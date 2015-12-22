SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[CVO_validate_promo_kits_sp]    Script Date: 07/23/2010  *****
SED007 -- Promo Kit
Object:      Procedure CVO_validate_promo_kits_sp  
Source file: CVO_validate_promo_kits_sp.sql
Author:		 Jesus Velazquez
Created:	 07/23/2010
Function:    Do not allow to allocate promo kit at least exists one frame with qty avail
Modified:    
Calls:    
Called by:   CVO_tdc_plw_so_alloc_management_sp -- tdc_plw_so_alloc_management_sp
Copyright:   Epicor Software 2010.  All rights reserved.  
v1.1 CB 12/09/2010 - Use new tdc_config option and change to IN() as res type should be frame or SUN
v1.2 CB	01/05/2013 - Replace cursor
*/

CREATE PROCEDURE  [dbo].[CVO_validate_promo_kits_sp]
	 @order_no  INT = 0 ,  
	 @order_ext INT = 0 
AS
BEGIN
	-- v1.2 Start
	DECLARE	@row_id			int,
			@last_row_id	int

	--add vars
	--DECLARE @frame VARCHAR(10) -- v1.1
	DECLARE @frame VARCHAR(20) -- v1.1
	--SET @frame = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_FRAME') -- v1.1
	SET @frame = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PROMO_KITS') -- v1.1

	IF @order_no > 0 --called by eBO -- if exists promo kits + frame
	BEGIN
		IF EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
				   FROM   CVO_qty_to_alloc_tbl	cvo_qty (NOLOCK),   
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
				   FROM   CVO_qty_to_alloc_tbl	cvo_qty (NOLOCK),   
						  inv_master			inv		(NOLOCK),
						  CVO_ord_list			cvo_ol	(NOLOCK) 
				   WHERE  cvo_qty.part_no	= inv.part_no		AND 
						  cvo_qty.order_no	= cvo_ol.order_no	AND
						  cvo_qty.order_ext = cvo_ol.order_ext	AND
						  cvo_qty.line_no	= cvo_ol.line_no	AND
						  cvo_qty.order_no	= @order_no			AND 
						  cvo_qty.order_ext = @order_ext		AND 
						  inv.type_code		IN (select * from fs_cParsing (@frame))) -- v1.1						  
						  --inv.type_code		= @frame) -- v1.1		
				  
		BEGIN
			--if not exists Frames with qty to alloc > 0 then update qty_to_alloc to 0
			IF NOT EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
						   FROM   CVO_qty_to_alloc_tbl		cvo_qty (NOLOCK),   
								  inv_master				inv		(NOLOCK),   
								  CVO_ord_list				cvo_ol	(NOLOCK)
				  		   WHERE  cvo_qty.part_no		= inv.part_no		AND 
						 		  cvo_qty.order_no		= cvo_ol.order_no	AND
						 		  cvo_qty.order_ext		= cvo_ol.order_ext	AND
						 		  cvo_qty.line_no		= cvo_ol.line_no	AND
						 		  cvo_qty.order_no		= @order_no			AND
						 		  cvo_qty.order_ext		= @order_ext		AND
						 		  inv.type_code			IN (select * from fs_cParsing (@frame))			AND -- v1.1
								  --inv.type_code			= @frame			AND -- v1.1
						 		  cvo_qty.qty_to_alloc	> 0)
							 
			BEGIN
				UPDATE  CVO_qty_to_alloc_tbl	
				SET		qty_to_alloc = 0
				WHERE	order_no	 = @order_no	AND 
						order_ext	 = @order_ext		
			END
		END			
	END

	IF @order_no = 0 --called by WMS
	BEGIN

		-- v1.2 Start
		CREATE TABLE #vk_detail_cursor (
			row_id		int IDENTITY(1,1),
			order_no	int,
			order_ext	int)

		INSERT	#vk_detail_cursor (order_no, order_ext)
		SELECT order_no, order_ext FROM #so_alloc_management--##header2

--		DECLARE detail_cursor CURSOR FOR 
--		SELECT order_no, order_ext FROM #so_alloc_management--##header2

--		OPEN detail_cursor

--		FETCH NEXT FROM detail_cursor 
--		INTO @order_no, @order_ext

--		WHILE @@FETCH_STATUS = 0
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
			IF EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
					   FROM   CVO_qty_to_alloc_tbl	cvo_qty (NOLOCK),   
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
					   FROM   CVO_qty_to_alloc_tbl	cvo_qty (NOLOCK),   
							  inv_master			inv		(NOLOCK),
							  CVO_ord_list			cvo_ol	(NOLOCK) 
					   WHERE  cvo_qty.part_no	= inv.part_no		AND 
							  cvo_qty.order_no	= cvo_ol.order_no	AND
							  cvo_qty.order_ext = cvo_ol.order_ext	AND
							  cvo_qty.line_no	= cvo_ol.line_no	AND
							  cvo_qty.order_no	= @order_no			AND 
							  cvo_qty.order_ext = @order_ext		AND 
							  inv.type_code		IN (select * from fs_cParsing (@frame))) -- v1.1							  
							  --inv.type_code		= @frame) -- v1.1 							  
			BEGIN
				--if not exists Frames with qty to alloc > 0 then update qty_to_alloc to 0
				IF NOT EXISTS (SELECT cvo_qty.*, inv.type_code, cvo_ol.promo_item
							   FROM   CVO_qty_to_alloc_tbl		cvo_qty (NOLOCK),   
									  inv_master				inv		(NOLOCK),   
									  CVO_ord_list				cvo_ol	(NOLOCK)
			  				   WHERE  cvo_qty.part_no		= inv.part_no		AND 
					 				  cvo_qty.order_no		= cvo_ol.order_no	AND
					 				  cvo_qty.order_ext		= cvo_ol.order_ext	AND
					 				  cvo_qty.line_no		= cvo_ol.line_no	AND
					 				  cvo_qty.order_no		= @order_no			AND
					 				  cvo_qty.order_ext		= @order_ext		AND
					 				  inv.type_code			IN (select * from fs_cParsing (@frame))			AND -- v1.1
					 				  --inv.type_code			= @frame			AND -- v1.1
					 				  cvo_qty.qty_to_alloc	> 0)
								 
				BEGIN
					UPDATE  CVO_qty_to_alloc_tbl	
					SET		qty_to_alloc = 0
					WHERE	order_no	 = @order_no	AND 
							order_ext	 = @order_ext	
							
					UPDATE  #so_allocation_detail_view	
					SET		qty_to_alloc = 0
					WHERE	order_no	 = @order_no	AND 
							order_ext	 = @order_ext								
				END
			END

			-- v1.2 Start
			SET @last_row_id = @row_id
			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext
			FROM	#vk_detail_cursor
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

--		   FETCH NEXT FROM detail_cursor 
--		   INTO @order_no, @order_ext
		END		
--		CLOSE detail_cursor
--		DEALLOCATE detail_cursor
		DROP TABLE #vk_detail_cursor
-- v1.2 End

	END
END
-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_validate_promo_kits_sp] TO [public]
GO
