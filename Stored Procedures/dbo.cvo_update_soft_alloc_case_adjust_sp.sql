SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_update_soft_alloc_case_adjust_sp]	@soft_alloc_no	int,
														@order_no		int, 
														@order_ext		int
AS
BEGIN

	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@line_no		int,
			@location		varchar(10),
			@part_no		varchar(30),
			@quantity		decimal(20,8),
			@row_id			int,
			@last_row_id	int,
			@new_qty		decimal(20,8)

	DECLARE @temp TABLE (
			row_id		int IDENTITY(1,1),
			line_no		int,
			case_part	varchar(30),
			qty			decimal(20,8),
			adj_qty		decimal(20,8))

	INSERT	@temp (line_no, case_part, qty, adj_qty)
	SELECT	a.line_no, a.part_no, a.ordered -  a.shipped, 0 -- v1.1 -a.shipped
	FROM	ord_list a (NOLOCK)
	JOIN	inv_master b (NOLOCK)
	ON		a.part_no = b.part_no
	JOIN	cvo_ord_list c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	AND		a.line_no = c.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.type_code = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')
	AND		c.is_case = 1

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@line_no = line_no,
			@part_no = case_part,
			@quantity = qty
	FROM	@temp
	WHERE	row_id > @last_row_id
	ORDER BY row_id

	WHILE @@ROWCOUNT <> 0
	BEGIN
	
		SET @new_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@part_no,'',-99,0,0)


		IF (@new_qty <> @quantity)
		BEGIN
			UPDATE	@temp
			SET		adj_qty = @new_qty - @quantity -- v1.2 @quantity - @new_qty
			WHERE	row_id = @row_id
		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@line_no = line_no,
				@part_no = case_part,
				@quantity = qty
		FROM	@temp
		WHERE	row_id > @last_row_id
		ORDER BY row_id
	END

	UPDATE	a
	SET		case_adjust = b.adj_qty
	FROM	cvo_soft_alloc_det a
	JOIN	@temp b
	ON		a.line_no = b.line_no
	AND		a.part_no = b.case_part
	WHERE	a.soft_alloc_no = @soft_alloc_no
	AND		a.status <> -2


END
GO
GRANT EXECUTE ON  [dbo].[cvo_update_soft_alloc_case_adjust_sp] TO [public]
GO
