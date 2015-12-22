SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_create_soft_alloc_sp]	@order_no		int, 
											@order_ext		int
AS 
BEGIN
	-- Declarations
	DECLARE @soft_alloc_no	int

	-- v1.2 Start
	SET @soft_alloc_no = NULL

	SELECT	@soft_alloc_no = soft_alloc_no
	FROM	cvo_soft_alloc_no_assign (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@soft_alloc_no IS NULL)
	BEGIN

		-- Get the next soft alloc number
		UPDATE	dbo.cvo_soft_alloc_next_no
		SET		next_no = next_no + 1	

		SELECT	@soft_alloc_no = next_no
		FROM	dbo.cvo_soft_alloc_next_no
	END
	-- v1.2 End

	-- Create the soft alloc header
	INSERT	dbo.cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
	SELECT	@soft_alloc_no, @order_no, @order_ext, location, 0, 1
	FROM	dbo.orders_all (NOLOCK)	
	WHERE	order_no = @order_no
	AND		ext = @order_ext	

	-- Create the soft alloc_detail
	INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
	SELECT	@soft_alloc_no, @order_no, @order_ext, line_no, location, part_no, ordered, 0, 0, 0, 0, 0, 0, 1 
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	
	-- v1.1 Start
	UPDATE	a	
	SET		inv_avail = b.inv_avail,
			kit_part = b.kit_part,
			is_case = b.is_case,
			is_pattern = b.is_pattern,
			is_pop_gift = b.is_pop_gift		
	FROM	cvo_soft_alloc_det a
	JOIN	cvo_soft_alloc_det b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.soft_alloc_no = @soft_alloc_no
	AND		b.soft_alloc_no <> @soft_alloc_no
	-- v1.1 End

	UPDATE	cvo_soft_alloc_det
	SET		status = 0
	WHERE	soft_alloc_no = @soft_alloc_no	

	UPDATE	cvo_soft_alloc_hdr
	SET		status = 0
	WHERE	soft_alloc_no = @soft_alloc_no	

END
GO
GRANT EXECUTE ON  [dbo].[cvo_create_soft_alloc_sp] TO [public]
GO
