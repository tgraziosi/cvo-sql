SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_backorder_sp]	@soft_alloc_no	int, -- 0 when called from backorder process else used by order duplication
											@order_no		int, 
											@order_ext		int,
											@new_ext		int	
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@line_no		int,
			@last_line_no	int,
			@from_line_no	int,
			@location		varchar(10),
			@part_no		varchar(30),
			@quantity		decimal(20,8),
			@kit_part		smallint,
			@add_case		smallint,
			@add_pattern	smallint,
			@deleted		smallint,
			@customer_code	varchar(10),
			@ship_to		varchar(10),
			@is_pop_gift	smallint,
			@ship_to_region char(2), 
			@tax_code		varchar(8),
			@back_ord_flag	smallint,
			@row_id			int,
			@last_row_id	int,
			@user_id		varchar(50),
			@bo_exists		int, -- v1.1
			@inv_avail		decimal(20,8), -- v1.2
			@new_qty		decimal(20,8), -- v1.4
			@pre_sa			SMALLINT -- v1.5

	-- v1.4 Start
	DECLARE @temp TABLE (
			row_id		int IDENTITY(1,1),
			line_no		int,
			case_part	varchar(30),
			qty			decimal(20,8),
			adj_qty		decimal(20,8))
	-- v1.4 End

	-- START v1.5
	CREATE TABLE #add_case (
		row_id	INT IDENTITY (1,1),
		frame_line_no INT,
		case_line_no INT)


	SET @pre_sa = 0 -- False
	IF EXISTS (SELECT 1 FROM dbo.cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND is_case = 1 AND from_line_no <> 0)
	BEGIN
		SET @pre_sa = 1 -- True

		-- Load frames which have cases added into temp table
		INSERT INTO #add_case (
			frame_line_no,
			case_line_no)
		SELECT 
			from_line_no, 
			MIN(line_no) 
		FROM 
			dbo.cvo_ord_list (NOLOCK) 
		WHERE
			order_no = @order_no 
			AND order_ext = @order_ext 
			AND is_case = 1 
			AND from_line_no <> 0 
		GROUP BY 
			from_line_no

	END
	-- v1.5
	


	IF @soft_alloc_no = 0 -- BackOrder
	BEGIN

		-- v1.1 If soft allocation does not exist
		SET @bo_exists = 0
		IF EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status = 0 AND bo_hold = 1)
		BEGIN
			SET @bo_exists = 1
			UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
			SET		order_ext = @new_ext
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		status = 0
			AND		bo_hold = 1

			UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
			SET		order_ext = @new_ext
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		status = 0

			-- v2.0 Start
			UPDATE	cvo_soft_alloc_no_assign WITH (ROWLOCK)
			SET		order_ext = @new_ext
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			-- v2.0 End

			RETURN
			
		END


		BEGIN TRAN
		UPDATE	dbo.cvo_soft_alloc_next_no
		SET		next_no = next_no + 1	

		SELECT	@soft_alloc_no = next_no
		FROM	dbo.cvo_soft_alloc_next_no
		COMMIT TRAN

		-- v1.8 Start
		IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_no_assign (NOLOCK) WHERE order_no = @order_no AND order_ext = @new_ext) -- v1.9 @order_ext)
		BEGIN
			INSERT	cvo_soft_alloc_no_assign  WITH (ROWLOCK) (order_no, order_ext, soft_alloc_no)
			VALUES (@order_no, @new_ext, @soft_alloc_no)
		END
		-- v1.8 End		

		INSERT	dbo.cvo_soft_alloc_hdr  WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		SELECT	DISTINCT @soft_alloc_no, @order_no, @new_ext, location, 1, 0
		FROM	dbo.orders_all (NOLOCK)	
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		INSERT INTO	dbo.cvo_soft_alloc_det  WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v1.3			
		SELECT	@soft_alloc_no, @order_no, @new_ext, a.line_no, a.location, a.part_no, a.ordered - a.shipped, -- v1.6 a.ordered - a.shipped instead of just a.ordered
				0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, 0, b.add_case -- v1.3
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		(a.ordered - a.shipped) > 0

		-- START v1.5 
		IF @pre_sa = 1
		BEGIN
			-- Update the add_case_flag on frames with cases
			UPDATE
				a
			SET
				add_case_flag = 'Y'
			FROM
				dbo.cvo_soft_alloc_det a  WITH (ROWLOCK)
			INNER JOIN
				#add_case b
			ON
				a.line_no = b.frame_line_no
			WHERE
				a.soft_alloc_no = @soft_alloc_no

			-- Update the cvo_ord_list records to the new format case relationship
			UPDATE	a
			SET		a.add_case = 'Y'
			FROM	cvo_ord_list a  WITH (ROWLOCK)
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.from_line_no
			WHERE	b.from_line_no <> 0
			AND		b.is_case = 1
			AND		a.order_no = @order_no
			AND		a.order_ext = @new_ext

			UPDATE	b
			SET		b.from_line_no = 0
			FROM	cvo_ord_list a (NOLOCK)
			JOIN	cvo_ord_list b  WITH (ROWLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.from_line_no
			WHERE	b.from_line_no <> 0
			AND		b.is_case = 1
			AND		a.order_no = @order_no
			AND		a.order_ext = @new_ext

		END
		-- END v1.5

		-- v1.4 Start - Calculate if the cases have been manually changed
		EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @soft_alloc_no, @order_no, @order_ext
		-- v1.4 End

		INSERT INTO	dbo.cvo_soft_alloc_det  WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
		SELECT	@soft_alloc_no,@order_no, @new_ext, a.line_no, a.location, b.part_no, a.ordered,
				1, 0, 0, 0, 0, 0, 0
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list_kit b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext	
		AND		b.replaced = 'S'	
		AND		(a.ordered - a.shipped) > 0

	
		INSERT	dbo.cvo_soft_alloc_hdr_posted  WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		SELECT	soft_alloc_no, order_no, order_ext, location, bo_hold, status
		FROM	dbo.cvo_soft_alloc_hdr
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2

		INSERT	dbo.cvo_soft_alloc_det_posted  WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
												kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, row_id)
		SELECT	soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
												kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, row_id
		FROM	dbo.cvo_soft_alloc_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2

		-- Clear the original soft allocation record
		DELETE	dbo.cvo_soft_alloc_hdr
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2
		  
		DELETE	dbo.cvo_soft_alloc_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2

		SET @last_line_no = 0

		SELECT	TOP 1 @line_no = line_no,
				@part_no = part_no,
				@quantity = ordered,
				@location = location
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @new_ext		
		AND		line_no > @last_line_no
		ORDER BY line_no ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN


			EXEC @inv_avail = dbo.CVO_GetAllocatableStock_sp @order_no, @new_ext, @location, @part_no, @quantity, @soft_alloc_no

			IF (@inv_avail >= @quantity)
			BEGIN
				UPDATE	cvo_soft_alloc_det  WITH (ROWLOCK)
				SET		inv_avail = 1
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		line_no = @line_no
			END

			SET @last_line_no = @line_no

			SELECT	TOP 1 @line_no = line_no,
					@part_no = part_no,
					@quantity = ordered,
					@location = location
			FROM	ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @new_ext		
			AND		line_no > @last_line_no
			ORDER BY line_no ASC
		END

		UPDATE	a
		SET		add_case = 'Y'
		FROM	cvo_ord_list a  WITH (ROWLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @new_ext
		AND		b.is_case = 1		

		UPDATE	a
		SET		add_pattern = 'Y'
		FROM	cvo_ord_list a  WITH (ROWLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @new_ext
		AND		b.is_pattern = 1		

		UPDATE	a
		SET		add_polarized = 'Y'
		FROM	cvo_ord_list a  WITH (ROWLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @new_ext
		AND		b.is_polarized = 1		

		UPDATE	cvo_ord_list WITH (ROWLOCK)
		SET		from_line_no = 0
		WHERE	order_no = @order_no
		AND		order_ext = @new_ext

		RETURN

	END
	ELSE
	BEGIN

		-- v1.2 Start
		-- Insert cvo_soft_alloc header
		INSERT	INTO cvo_soft_alloc_hdr  WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		SELECT	@soft_alloc_no, 0, 0, location, 0, 0
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext		

		INSERT INTO	dbo.cvo_soft_alloc_det  WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v1.3			
		SELECT	@soft_alloc_no, 0, 0, a.line_no, a.location, a.part_no, a.ordered, -- v1.7 Do no subtract shipped as this is duplicating
				0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, 0, b.add_case -- v1.3
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext

		-- START v1.5 - Update the add_case_flag on frames with cases
		IF @pre_sa = 1
		BEGIN
			UPDATE
				a
			SET
				add_case_flag = 'Y'
			FROM
				dbo.cvo_soft_alloc_det a  WITH (ROWLOCK)
			INNER JOIN
				#add_case b
			ON
				a.line_no = b.frame_line_no
			WHERE
				a.soft_alloc_no = @soft_alloc_no
		END
		-- END v1.5

		-- v1.4 Start - Calculate if the cases have been manually changed
		EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @soft_alloc_no, @order_no, @order_ext
		-- v1.4 End

		INSERT INTO	dbo.cvo_soft_alloc_det  WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
		SELECT	@soft_alloc_no, 0, 0, a.line_no, a.location, b.part_no, a.ordered,
				1, 0, 0, 0, 0, 0, 0
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list_kit b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext	
		AND		b.replaced = 'S'	

		SET @last_line_no = 0

		SELECT	TOP 1 @line_no = line_no,
				@part_no = part_no,
				@quantity = ordered,
				@location = location
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext		
		AND		line_no > @last_line_no
		ORDER BY line_no ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN


			EXEC @inv_avail = dbo.CVO_GetAllocatableStock_sp @order_no, @order_ext, @location, @part_no, @quantity, @soft_alloc_no

			IF (@inv_avail >= @quantity)
			BEGIN
				UPDATE	cvo_soft_alloc_det  WITH (ROWLOCK)
				SET		inv_avail = 1
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		line_no = @line_no
			END

			SET @last_line_no = @line_no

			SELECT	TOP 1 @line_no = line_no,
					@part_no = part_no,
					@quantity = ordered,
					@location = location
			FROM	ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext		
			AND		line_no > @last_line_no
			ORDER BY line_no ASC
		END

		SELECT 0

		RETURN
		-- v1.2 End
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_backorder_sp] TO [public]
GO
