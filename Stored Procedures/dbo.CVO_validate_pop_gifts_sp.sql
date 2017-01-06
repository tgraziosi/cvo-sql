SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CB 11/11/2015 - #1576 - POP should not allocate on there own when frames are on the order and do not allocate
-- v1.1 CB 21/06/2016 - If there are no frames on the order then allow the POP to allocate
-- v1.2 CB 06/01/2016 - DCF - Check for kit part

CREATE PROC [dbo].[CVO_validate_pop_gifts_sp]	@order_no  int = 0,  
											@order_ext int = 0 
AS
BEGIN

	DECLARE	@row_id			int,
			@last_row_id	int,
			@frame			varchar(20)
	
	SET @frame = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PROMO_KITS') 

	IF (@order_no > 0) --called by eBO -- if exists promo kits + frame
	BEGIN
		IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
					AND is_pop_gif = 1)
		BEGIN
			IF EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN cvo_ord_list b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.order_ext
				AND a.line_no = b.line_no WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND a.shipped < a.ordered 
				AND	b.is_pop_gif = 0)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM #so_allocation_detail_view_Detail a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.part_no = b.part_no
					WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND b.type_code IN (SELECT * FROM fs_cParsing (@frame))
					AND a.qty_to_alloc > 0) -- v1.2 Start
					AND NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND part_type = 'C') -- v1.2 End	
				BEGIN
					-- v1.1 Start
					IF EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.part_no = b.part_no
						WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND b.type_code IN (SELECT * FROM fs_cParsing (@frame)))
					BEGIN
						UPDATE	a
						SET		qty_to_alloc = 0
						FROM	#so_allocation_detail_view_Detail a
						JOIN	cvo_ord_list b (NOLOCK)
						ON		a.order_no = b.order_no
						AND		a.order_ext = b.order_ext
						AND		a.line_no = b.line_no
						WHERE	a.order_no = @order_no
						AND		a.order_ext = @order_ext
						AND		b.is_pop_gif = 1
					END
					-- v1.1 End
				END
			END
		END
	END

	IF (@order_no = 0) --called by WMS
	BEGIN

		-- v1.2 Start
		CREATE TABLE #vk_detail_cursor (
			row_id		int IDENTITY(1,1),
			order_no	int,
			order_ext	int)

		INSERT	#vk_detail_cursor (order_no, order_ext)
		SELECT order_no, order_ext FROM #so_alloc_management--##header2

		SET @last_row_id = 0
		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#vk_detail_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		-- v1.2 End
		BEGIN
			IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
					AND is_pop_gif = 1)
			BEGIN
				IF EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN cvo_ord_list b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.order_ext
					AND a.line_no = b.line_no WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND a.shipped < a.ordered 
					AND	b.is_pop_gif = 0)
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM #so_allocation_detail_view a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.part_no = b.part_no
						WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND b.type_code IN (SELECT * FROM fs_cParsing (@frame))
						AND a.qty_to_alloc > 0) -- v1.2 Start
						AND NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND part_type = 'C') -- v1.2 End		
					BEGIN
						-- v1.1 Start
						IF EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.part_no = b.part_no
							WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND b.type_code IN (SELECT * FROM fs_cParsing (@frame)))
						BEGIN
							UPDATE	a
							SET		qty_to_alloc = 0
							FROM	#so_allocation_detail_view a
							JOIN	cvo_ord_list b (NOLOCK)
							ON		a.order_no = b.order_no
							AND		a.order_ext = b.order_ext
							AND		a.line_no = b.line_no
							WHERE	a.order_no = @order_no
							AND		a.order_ext = @order_ext
							AND		b.is_pop_gif = 1

							UPDATE	a
							SET		qty_to_alloc = 0
							FROM	CVO_qty_to_alloc_tbl a
							JOIN	cvo_ord_list b (NOLOCK)
							ON		a.order_no = b.order_no
							AND		a.order_ext = b.order_ext
							AND		a.line_no = b.line_no
							WHERE	a.order_no = @order_no
							AND		a.order_ext = @order_ext
							AND		b.is_pop_gif = 1
						END
						-- v1.1 End
					END
				END
			END

			SET @last_row_id = @row_id
			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext
			FROM	#vk_detail_cursor
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

		END		
		DROP TABLE #vk_detail_cursor


	END
END
-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_validate_pop_gifts_sp] TO [public]
GO
