SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_sim_validate_promo_kits_sp] 	@order_no  INT = 0 ,  
												@order_ext INT = 0 
AS
BEGIN
	-- NOTE: Routine based on CVO_validate_promo_kits_sp v1.2 - All changes must be kept in sync

	DECLARE	@row_id			int,
			@last_row_id	int

	DECLARE @frame VARCHAR(20)
	SET @frame = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PROMO_KITS')

	IF @order_no > 0 --called by eBO -- if exists promo kits + frame
	BEGIN
		IF EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
				   FROM   #sim_CVO_qty_to_alloc_tbl	cvo_qty (NOLOCK),   
						  inv_master			inv		(NOLOCK),
						  CVO_ord_list			cvo_ol	(NOLOCK) 
				   WHERE  cvo_qty.part_no	= inv.part_no		AND 
						  cvo_qty.order_no	= cvo_ol.order_no	AND
						  cvo_qty.order_ext = cvo_ol.order_ext	AND
						  cvo_qty.line_no	= cvo_ol.line_no	AND
						  cvo_qty.order_no	= @order_no			AND 
						  cvo_qty.order_ext = @order_ext		AND 
						  cvo_ol.promo_item = 'Y')              AND
			EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
				   FROM   #sim_CVO_qty_to_alloc_tbl	cvo_qty (NOLOCK),   
						  inv_master			inv		(NOLOCK),
						  CVO_ord_list			cvo_ol	(NOLOCK) 
				   WHERE  cvo_qty.part_no	= inv.part_no		AND 
						  cvo_qty.order_no	= cvo_ol.order_no	AND
						  cvo_qty.order_ext = cvo_ol.order_ext	AND
						  cvo_qty.line_no	= cvo_ol.line_no	AND
						  cvo_qty.order_no	= @order_no			AND 
						  cvo_qty.order_ext = @order_ext		AND 
						  inv.type_code		IN (select * from fs_cParsing (@frame))) 
				  
		BEGIN
			--if not exists Frames with qty to alloc > 0 then update qty_to_alloc to 0
			IF NOT EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
						   FROM   #sim_CVO_qty_to_alloc_tbl		cvo_qty (NOLOCK),   
								  inv_master				inv		(NOLOCK),   
								  CVO_ord_list				cvo_ol	(NOLOCK)
				  		   WHERE  cvo_qty.part_no		= inv.part_no		AND 
						 		  cvo_qty.order_no		= cvo_ol.order_no	AND
						 		  cvo_qty.order_ext		= cvo_ol.order_ext	AND
						 		  cvo_qty.line_no		= cvo_ol.line_no	AND
						 		  cvo_qty.order_no		= @order_no			AND
						 		  cvo_qty.order_ext		= @order_ext		AND
						 		  inv.type_code			IN (select * from fs_cParsing (@frame))			AND 
						 		  cvo_qty.qty_to_alloc	> 0)
							 
			BEGIN
				UPDATE  #sim_CVO_qty_to_alloc_tbl	
				SET		qty_to_alloc = 0
				WHERE	order_no	 = @order_no	AND 
						order_ext	 = @order_ext		
			END
		END			
	END

	IF @order_no = 0 --called by WMS
	BEGIN

		CREATE TABLE #vk_detail_cursor (
			row_id		int IDENTITY(1,1),
			order_no	int,
			order_ext	int)

		INSERT	#vk_detail_cursor (order_no, order_ext)
		SELECT order_no, order_ext FROM #so_alloc_management

		SET @last_row_id = 0
		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#vk_detail_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN
			IF EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
					   FROM   #sim_CVO_qty_to_alloc_tbl	cvo_qty (NOLOCK),   
							  inv_master			inv		(NOLOCK),
							  CVO_ord_list			cvo_ol	(NOLOCK) 
					   WHERE  cvo_qty.part_no	= inv.part_no		AND 
							  cvo_qty.order_no	= cvo_ol.order_no	AND
							  cvo_qty.order_ext = cvo_ol.order_ext	AND
							  cvo_qty.line_no	= cvo_ol.line_no	AND
							  cvo_qty.order_no	= @order_no			AND 
							  cvo_qty.order_ext = @order_ext		AND 
							  cvo_ol.promo_item = 'Y')              AND
				EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
					   FROM   #sim_CVO_qty_to_alloc_tbl	cvo_qty (NOLOCK),   
							  inv_master			inv		(NOLOCK),
							  CVO_ord_list			cvo_ol	(NOLOCK) 
					   WHERE  cvo_qty.part_no	= inv.part_no		AND 
							  cvo_qty.order_no	= cvo_ol.order_no	AND
							  cvo_qty.order_ext = cvo_ol.order_ext	AND
							  cvo_qty.line_no	= cvo_ol.line_no	AND
							  cvo_qty.order_no	= @order_no			AND 
							  cvo_qty.order_ext = @order_ext		AND 
							  inv.type_code		IN (select * from fs_cParsing (@frame))) 
			BEGIN
				--if not exists Frames with qty to alloc > 0 then update qty_to_alloc to 0
				IF NOT EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
							   FROM   #sim_CVO_qty_to_alloc_tbl		cvo_qty (NOLOCK),   
									  inv_master				inv		(NOLOCK),   
									  CVO_ord_list				cvo_ol	(NOLOCK)
			  				   WHERE  cvo_qty.part_no		= inv.part_no		AND 
					 				  cvo_qty.order_no		= cvo_ol.order_no	AND
					 				  cvo_qty.order_ext		= cvo_ol.order_ext	AND
					 				  cvo_qty.line_no		= cvo_ol.line_no	AND
					 				  cvo_qty.order_no		= @order_no			AND
					 				  cvo_qty.order_ext		= @order_ext		AND
					 				  inv.type_code			IN (select * from fs_cParsing (@frame))			AND
					 				  cvo_qty.qty_to_alloc	> 0)
								 
				BEGIN
					UPDATE  #sim_CVO_qty_to_alloc_tbl	
					SET		qty_to_alloc = 0
					WHERE	order_no	 = @order_no	AND 
							order_ext	 = @order_ext	
							
					UPDATE  #so_allocation_detail_view	
					SET		qty_to_alloc = 0
					WHERE	order_no	 = @order_no	AND 
							order_ext	 = @order_ext								
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
GO
GRANT EXECUTE ON  [dbo].[CVO_sim_validate_promo_kits_sp] TO [public]
GO
