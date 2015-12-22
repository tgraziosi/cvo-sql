SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC	[dbo].[cvo_recreate_sa_sp]	@order_no	int,
									@order_ext	int
AS
BEGIN

	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@soft_alloc_no	int,
			@last_line_no	int,
			@line_no		int,
			@part_no		varchar(30),
			@quantity		decimal(20,8),
			@location		varchar(10),
			@inv_avail		decimal(20,8)

	SELECT	@soft_alloc_no = soft_alloc_no
	FROM	cvo_soft_alloc_no_assign (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@soft_alloc_no IS NULL)
		RETURN

	-- Insert cvo_soft_alloc header
	INSERT	INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
	SELECT	@soft_alloc_no, @order_no, @order_ext, location, 0, 0
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext		

	INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
								kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) 
	SELECT	@soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, a.ordered, 
			0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, 0, b.add_case 
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext

	EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @soft_alloc_no, @order_no, @order_ext

	INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
								kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
	SELECT	@soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, a.ordered,
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
			UPDATE	cvo_soft_alloc_det
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
END
GO
GRANT EXECUTE ON  [dbo].[cvo_recreate_sa_sp] TO [public]
GO
