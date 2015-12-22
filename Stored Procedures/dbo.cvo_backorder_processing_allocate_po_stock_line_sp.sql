SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*

BEGIN TRAN
declare @err_msg varchar(500)
EXEC cvo_backorder_processing_allocate_po_stock_line_sp 1, 1419647,0,1,'cbbla5800','001',5,0,'potest1',@err_msg output
select @err_msg
--COMMIT TRAN
--ROLLBACK TRAN
*/
-- v1.1 CB 05/07/2013 - Issue #1325 - Keep soft alloc number
-- v1.2 CT 15/07/2013 - Issue #695 - If this is a case and the line is fully allocated then don't return an error
-- v1.3 CT 24/07/2013 - Issue #695 - Fix bin_no field in #ringfenced table

CREATE PROC [dbo].[cvo_backorder_processing_allocate_po_stock_line_sp] (@rec_id			INT,
																	@order_no		INT,
																	@ext			INT,
																	@line_no		INT,
																	@part_no		VARCHAR(30),
																	@location		VARCHAR(10),
																	@qty			DECIMAL(20,8),
																	@is_transfer	SMALLINT,
																	@template_code	VARCHAR(30),
																	@err_msg		VARCHAR(500) OUTPUT)

AS
BEGIN
	DECLARE @retval				SMALLINT,
			@r_rec_id			INT,
			@r_bin_no			VARCHAR(12), 
			@r_orig_bin_no		VARCHAR(12), 
			@r_qty				DECIMAL(20,8),
			@r_location			VARCHAR(10),
			@multi_line			SMALLINT,
			@msg				VARCHAR(1000),
			@pol_line_no		INT,
			@sa_qty				DECIMAL(20,8),
			@alloc_qty			DECIMAL(20,8),
			@new_soft_alloc_no	INT,
			@rollback			SMALLINT,
			@os_qty				DECIMAL(20,8),
			@case_allocated		SMALLINT -- v1.2
	
	SET @retval = 0
	SET @err_msg =''
	SET @rollback = 0
	SET @case_allocated = 0 -- v1.2

	-- Check order isn't void or on a non-allocatable hold
	IF @is_transfer = 0
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND ISNULL(void,'N') = 'N')
		BEGIN
			SET @err_msg ='Order is void'
			RETURN -1
		END

		IF EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND [status] = 'A' AND hold_reason IN (SELECT hold_code FROM dbo.cvo_hold_reason_no_autoalloc (NOLOCK)))
		BEGIN
			SET @err_msg ='Order is on a non allocatable hold reason'
			RETURN -1
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.xfers (NOLOCK) WHERE xfer_no = @order_no AND [status] = 'V')
		BEGIN
			SET @err_msg ='Transfer is void'
			RETURN -1
		END
	END	

	-- Begin transaction
	BEGIN TRAN
	
	-- Create allocation tables
	CREATE TABLE #backorder_processing_po_allocation_summary(
		order_no		INT,
		ext				INT,
		line_no			INT,
		part_no			VARCHAR(30),
		location		VARCHAR(10),
		qty				DECIMAL(20,8),
		allocated		DECIMAL(20,8),
		is_frame		SMALLINT,
		is_case			SMALLINT,
		is_pattern		SMALLINT,
		is_polarized	SMALLINT)


	CREATE TABLE #backorder_processing_po_allocation(
		parent_rec_id	INT,
		order_no		INT,
		ext				INT,
		line_no			INT,
		part_no			VARCHAR(30),
		location		VARCHAR(10),
		bin_no			VARCHAR(12),
		qty				DECIMAL(20,8),
		allocated		DECIMAL(20,8),
		is_frame		SMALLINT,
		is_case			SMALLINT,
		is_pattern		SMALLINT,
		is_polarized	SMALLINT)


	-- Create processing table
	CREATE TABLE #ringfenced(
		rec_id			INT,
		parent_rec_id	INT,
		order_no		INT,
		ext				INT,
		line_no			INT,
		part_no			VARCHAR(30),
		location		VARCHAR(10),
		-- START v1.3
		bin_no			VARCHAR(12),
		--bin_no			VARCHAR(10),
		-- END v1.3
		orig_bin_no		VARCHAR(12),
		qty				DECIMAL(20,8))

	-- Load details
	INSERT INTO #ringfenced (
		rec_id,
		parent_rec_id,
		order_no,
		ext,
		line_no,
		part_no,
		location,
		bin_no,
		orig_bin_no,
		qty)
	SELECT
		rec_id,
		parent_rec_id,
		@order_no,
		@ext,
		@line_no,
		@part_no,
		location,
		bin_no,
		orig_bin_no,
		qty
	FROM
		dbo.CVO_backorder_processing_orders_po_xref_trans (NOLOCK)
	WHERE
		parent_rec_id = @rec_id
		AND processed = 1
	ORDER BY
		rec_id

	IF @@ROWCOUNT = 0
	BEGIN
		SET @rollback = 1
		SET @err_msg = 'No PO stock ringfenced'
		GOTO retvals
	END

	-- Get qty outstatnding on this line
	IF @is_transfer = 0 
	BEGIN
		SELECT
			@os_qty = a.ordered - (a.shipped + ISNULL(b.qty,0))
		FROM
			dbo.ord_list a (NOLOCK)
		LEFT JOIN
			dbo.cvo_hard_allocated_vw b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.order_ext = b.order_ext
			AND a.line_no = b.line_no
			AND b.order_type = 'S'
		WHERE
			a.order_no = @order_no
			AND a.order_ext = @ext
			AND a.line_no = @line_no
	END
	ELSE
	BEGIN
		SELECT
			@os_qty = a.ordered - (a.shipped + ISNULL(b.qty,0))
		FROM
			dbo.xfer_list a (NOLOCK)
		LEFT JOIN
			dbo.cvo_hard_allocated_vw b (NOLOCK)
		ON
			a.xfer_no = b.order_no
			AND a.line_no = b.line_no
			AND b.order_type = 'T'
		WHERE
			a.xfer_no = @order_no
			AND a.line_no = @line_no
			
	END
	
	-- Check the order line still requires this much stock
	IF (SELECT SUM(qty) FROM #ringfenced) > ISNULL(@os_qty,0)
	BEGIN
		-- START v1.2
		IF EXISTS (SELECT 1 FROM dbo.inv_master (NOLOCK) WHERE type_code = 'CASE' AND part_no = @part_no)
		BEGIN
			SET @case_allocated = 1
		END
		ELSE
		BEGIN
			SET @rollback = 1
			SET @err_msg = 'Too much stock ringfenced for this order line'
			GOTO retvals
		END
		-- END v1.2
	END

	-- For stock which is not in CROSSDOCK bins, release the stock back to original bin		
	SET @r_rec_id = 0
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@r_rec_id = rec_id,
			@r_bin_no = bin_no,
			@r_orig_bin_no = orig_bin_no,
			@r_qty = qty,
			@r_location = location
		FROM
			#ringfenced
		WHERE
			rec_id > @r_rec_id
			AND orig_bin_no IS NOT NULL
		ORDER BY
			rec_id
	
		IF @@ROWCOUNT = 0
			BREAK

		-- Check the ringfence bin contains enough stock
		IF NOT EXISTS (SELECT 1 FROM dbo.lot_bin_stock (NOLOCK) WHERE part_no = @part_no AND location = @r_location AND bin_no = @r_bin_no AND qty >= @r_qty)
		BEGIN
			SET @rollback = 1
			SET @err_msg = 'Not enough stock in ringfence bin'
			GOTO retvals
		END
		
		-- Move stock back to original bin
		EXEC cvo_bin2bin_sp @part_no, @r_location, @r_bin_no, @r_orig_bin_no, @r_qty, 'BO Process' 	
	END
	
	-- Load temporary table with parts to allocated
	-- This part
	INSERT INTO #backorder_processing_po_allocation(
		parent_rec_id,
		order_no,
		ext,
		line_no,
		part_no,
		location,
		bin_no,
		qty,
		allocated,
		is_frame,
		is_case,
		is_pattern,
		is_polarized)
	SELECT
		parent_rec_id,
		order_no,
		ext,
		line_no,
		part_no,
		location,
		CASE ISNULL(orig_bin_no,'') WHEN '' THEN bin_no ELSE NULL END,
		SUM(qty),
		0,
		1,
		0,
		0,
		0
	FROM
		#ringfenced
	GROUP BY
		parent_rec_id,
		order_no,
		ext,
		line_no,
		part_no,
		location,
		orig_bin_no,
		bin_no

	IF @is_transfer = 0
	BEGIN
		-- Linked case
		IF EXISTS (SELECT 1 FROM dbo.cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND ISNULL(add_case,'N') = 'Y')
		BEGIN
			INSERT INTO #backorder_processing_po_allocation(
				order_no,
				ext,
				line_no,
				part_no,
				location,
				qty,
				allocated,
				is_frame,
				is_case,
				is_pattern,
				is_polarized)
			SELECT TOP 1
				a.order_no,
				a.order_ext,
				a.line_no,
				a.part_no,
				a.location,
				CASE WHEN @qty < (a.ordered - a.shipped) THEN @qty ELSE (a.ordered - a.shipped) END,
				0,
				0,
				1,
				0,
				0
			FROM
				dbo.ord_list a (NOLOCK)
			INNER JOIN
				dbo.cvo_ord_list_fc b (NOLOCK)
			ON
				a.order_no = b.order_no
				AND a.order_ext = b.order_ext 
				AND a.part_no = b.case_part
			INNER JOIN
				dbo.cvo_ord_list c (NOLOCK)
			ON
				a.order_no = c.order_no
				AND a.order_ext = c.order_ext 
				AND a.line_no = c.line_no
			WHERE
				a.order_no = @order_no
				AND a.order_ext = @ext
				AND b.line_no = @line_no
				AND ISNULL(c.is_case,0) = 1
				AND a.ordered > a.shipped
		END

		-- Linked pattern
		IF EXISTS (SELECT 1 FROM dbo.cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND ISNULL(add_pattern,'N') = 'Y')
		BEGIN
			INSERT INTO #backorder_processing_po_allocation(
			order_no,
			ext,
			line_no,
			part_no,
			location,
			qty,
			allocated,
			is_frame,
			is_case,
			is_pattern,
			is_polarized)
			SELECT TOP 1
			a.order_no,
			a.order_ext,
			a.line_no,
			a.part_no,
			a.location,
			1,
			0,
			0,
			0,
			1,
			0
		FROM
			dbo.ord_list a (NOLOCK)
		INNER JOIN
			dbo.cvo_ord_list_fc b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.order_ext = b.order_ext 
			AND a.part_no = b.pattern_part
		INNER JOIN
			dbo.cvo_ord_list c (NOLOCK)
		ON
			a.order_no = c.order_no
			AND a.order_ext = c.order_ext 
			AND a.line_no = c.line_no
		WHERE
			a.order_no = @order_no
			AND a.order_ext = @ext
			AND b.line_no = @line_no
			AND ISNULL(c.is_pattern,0) = 1
			AND a.ordered > a.shipped
		END

		-- Linked polarized
		SET @pol_line_no = 0
		
		SELECT 
			@pol_line_no = CAST(ISNULL(cust_po,'0') AS INT)
		FROM
			dbo.ord_list (NOLOCK)
		WHERE
			order_no = @order_no
			AND order_ext = @ext
			AND cust_po = CAST(@line_no AS VARCHAR(5))
			
		IF ISNULL(@pol_line_no,0) > 0
		BEGIN

			INSERT INTO #backorder_processing_po_allocation(
				order_no,
				ext,
				line_no,
				part_no,
				location,
				qty,
				allocated,
				is_frame,
				is_case,
				is_pattern,
				is_polarized)
			SELECT TOP 1
				order_no,
				order_ext,
				line_no,
				part_no,
				location,
				CASE WHEN @qty < (ordered - shipped) THEN @qty ELSE (ordered - shipped) END,
				0,
				0,
				0,
				0,
				1
			FROM
				dbo.ord_list  (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @pol_line_no
				AND ordered > shipped
		END		
	END

	-- Update with what's already allocated 
	UPDATE 
		a
	SET
		allocated = ISNULL(b.qty,0)
	FROM
		#backorder_processing_po_allocation a
	LEFT JOIN
		dbo.cvo_hard_allocated_vw b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.order_ext
		AND a.line_no = b.line_no
		AND ((@is_transfer = 0 AND b.order_type = 'S') OR (@is_transfer = 1 AND b.order_type = 'T'))

	INSERT INTO #backorder_processing_po_allocation_summary(
		order_no,
		ext,
		line_no,
		part_no,
		location,
		qty,
		allocated,
		is_frame,
		is_case,
		is_pattern,
		is_polarized)
	SELECT
		order_no,
		ext,
		line_no,
		part_no,
		location,
		SUM(qty),
		allocated,
		is_frame,
		is_case,
		is_pattern,
		is_polarized
	FROM
		#backorder_processing_po_allocation
	GROUP BY	
		order_no,
		ext,
		line_no,
		part_no,
		location,
		allocated,
		is_frame,
		is_case,
		is_pattern,
		is_polarized

	-- Allocate
	IF @is_transfer = 0
	BEGIN
		-- START v1.2
		IF @case_allocated = 0
		BEGIN
			EXEC dbo.tdc_order_after_save @order_no, @ext
		END
		ELSE
		BEGIN
			EXEC dbo.cvo_backorder_processing_log_sp 'Case line already allocated, skipping allocation'
		END
		-- END v1.2
	END
	ELSE
	BEGIN
		EXEC dbo.cvo_xfer_after_save_sp	@order_no
	END

	
	-- Update soft alloc records
	IF @is_transfer = 0
	BEGIN
		CREATE TABLE #tmp_alloc (
			line_no		int,
			qty			decimal(20,8))

		SELECT	@alloc_qty = SUM(qty) 
		FROM	tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext= @ext

		IF (@alloc_qty IS NULL)
			SET @alloc_qty = 0

		INSERT	#tmp_alloc
		SELECT	line_no, SUM(qty)
		FROM	tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext= @ext
		GROUP BY line_no

		SELECT	@sa_qty = SUM(ordered)
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @ext

		IF	(@sa_qty = @alloc_qty) -- Line Fully allocated
		BEGIN

			UPDATE	cvo_soft_alloc_det
			SET		status = -2
			WHERE	order_no = @order_no
			AND		order_ext = @ext
			AND		status IN (0,-1,-3)
			
			IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND status IN (0,-1,-3))
			BEGIN
				UPDATE	cvo_soft_alloc_hdr
				SET		status = -2
				WHERE	order_no = @order_no
				AND		order_ext = @ext
				AND		status IN (0,-1,-3)
			END
			-- v1.1 Start
			DELETE	cvo_soft_alloc_hdr
			WHERE	order_no = @order_no
			AND		order_ext = @ext
			AND		status = -2

			DELETE	cvo_soft_alloc_det
			WHERE	order_no = @order_no
			AND		order_ext = @ext
			AND		status = -2
			-- v1.1 End
		END
		ELSE
		BEGIN
			IF (@alloc_qty > 0) -- Lines partially allocated
			BEGIN

				UPDATE	cvo_soft_alloc_hdr
				SET		status = -2
				WHERE	order_no = @order_no
				AND		order_ext= @ext
				AND		status IN (0,-1,-3)

				UPDATE	cvo_soft_alloc_det
				SET		status = -2
				WHERE	order_no = @order_no
				AND		order_ext= @ext				
				AND		status IN (0,-1,-3)

				-- v1.1 Start
				DELETE	cvo_soft_alloc_hdr
				WHERE	order_no = @order_no
				AND		order_ext = @ext
				AND		status = -2

				DELETE	cvo_soft_alloc_det
				WHERE	order_no = @order_no
				AND		order_ext = @ext
				AND		status = -2
			
				SET @new_soft_alloc_no =  NULL

				SELECT	@new_soft_alloc_no = soft_alloc_no
				FROM	cvo_soft_alloc_no_assign (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @ext
				
				IF (@new_soft_alloc_no IS NULL)
				BEGIN
					BEGIN TRAN
						UPDATE	dbo.cvo_soft_alloc_next_no
						SET		next_no = next_no + 1
					COMMIT TRAN	
					SELECT	@new_soft_alloc_no = next_no
					FROM	dbo.cvo_soft_alloc_next_no
				END
				-- v1.1 End

				-- Get location if NULL
				IF @location IS NULL
				BEGIN
					SELECT @location = location FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext
				END

				-- Insert cvo_soft_alloc header
				INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
				VALUES (@new_soft_alloc_no, @order_no, @ext, @location, 0, 0)		

				INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
											kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag)	-- 10.5		
				SELECT	@new_soft_alloc_no, @order_no, @ext, a.line_no, a.location, a.part_no, (a.ordered - ISNULL(c.qty,0)),
						0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, 0, b.add_case 
				FROM	ord_list a (NOLOCK)
				JOIN	cvo_ord_list b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				AND		a.line_no = b.line_no
				LEFT JOIN
						#tmp_alloc c (NOLOCK)
				ON		a.line_no = c.line_no
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @ext
				AND		(a.ordered - ISNULL(c.qty,0)) > 0

				-- v10.6
				EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @new_soft_alloc_no, @order_no, @ext

				INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
											kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
				SELECT	@new_soft_alloc_no, @order_no, @ext, a.line_no, a.location, b.part_no, (a.ordered - ISNULL(c.qty,0)),
						1, 0, 0, 0, 0, 0, 0
				FROM	ord_list a (NOLOCK)
				JOIN	cvo_ord_list_kit b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				AND		a.line_no = b.line_no
				LEFT JOIN
						#tmp_alloc c (NOLOCK)
				ON		a.line_no = c.line_no
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @ext	
				AND		b.replaced = 'S'	
				AND		(a.ordered - ISNULL(c.qty,0)) > 0	
			END

		END

		DROP TABLE #tmp_alloc
	END

	-- Update trans records to mark them as complete
	UPDATE
		a
	SET 
		processed = 2
	FROM
		dbo.CVO_backorder_processing_orders_po_xref_trans a
	INNER JOIN
		#ringfenced b
	ON
		a.rec_id = b.rec_id
	
retvals:
	IF @rollback = 0
	BEGIN
		COMMIT TRAN
	END
	ELSE
	BEGIN
		ROLLBACK TRAN
		SET @retval = -1
	END
	
	RETURN @retval
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_allocate_po_stock_line_sp] TO [public]
GO
