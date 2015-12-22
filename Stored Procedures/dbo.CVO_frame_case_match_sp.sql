SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[CVO_frame_case_match_sp]    Script Date: 04/01/2010  *****
SED003 -- Case Part
Object:      Procedure CVO_frame_case_match_sp  
Source file: CVO_frame_case_match_sp.sql
Author:		 Jesus Velazquez
Created:	 04/05/2010
Function:    Calculates qty_to_alloc on every allocation screen refresh
Modified:    
Calls:    
Called by:   WMS74 -- Allocation Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
*/
CREATE PROCEDURE [dbo].[CVO_frame_case_match_sp] AS
BEGIN

DECLARE @case VARCHAR(10)
SET     @case = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')



--clean temp tables tables
DELETE FROM #so_alloc_management_Match
DELETE FROM #so_allocation_detail_view_Match

DELETE FROM #so_alloc_management_NO_match
DELETE FROM #so_allocation_detail_view_NO_match

return


DECLARE  @order_no				INT
		,@order_ext				INT 
		,@location				VARCHAR(30)
		,@line_no				INT
		,@part_no				VARCHAR(30)
		,@frame_case_match		INT

DECLARE temp_orders_cur CURSOR FOR
		  					SELECT order_no, order_ext, location FROM #so_alloc_management_Header --WHERE order_no <= 300 

	OPEN temp_orders_cur
	
	FETCH NEXT FROM temp_orders_cur INTO @order_no, @order_ext, @location
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @frame_case_match = 1
		IF(SELECT SUM(qty_picked) + SUM(qty_alloc) 
		   FROM #so_allocation_detail_view_Detail 
		   WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location) = 0
		   --sales order without allocation or packing		
		BEGIN	
						
			DECLARE temp_alloc_line_cur CURSOR FOR 
									SELECT	line_no, part_no--, qty_alloc 
									FROM	#so_allocation_detail_view_Detail 
									WHERE	from_line_no	= 0				AND 
											order_no		= @order_no		AND  
											order_ext		= @order_ext	AND  
											location		= @location	
									ORDER BY line_no, part_no
			OPEN temp_alloc_line_cur							
			FETCH NEXT FROM temp_alloc_line_cur INTO @line_no, @part_no	
									
		WHILE @@FETCH_STATUS = 0				
			BEGIN		

				--Exists Frame + Case ?
				IF EXISTS(SELECT * 
						  FROM	 #so_allocation_detail_view_Detail 
						  WHERE	(line_no = @line_no OR (from_line_no = @line_no AND type_code = @case)) AND		--((from_line_no = @line_no AND is_case = 1) OR line_no = @line_no)	AND
								 order_no		= @order_no												AND  
								 order_ext		= @order_ext											AND  
								 location		= @location)													 
				BEGIN

					IF EXISTS(SELECT * 
							  FROM	 #so_allocation_detail_view_Detail 
							  WHERE	(line_no = @line_no OR (from_line_no = @line_no AND type_code = @case)) AND	 --((from_line_no = @line_no AND is_case = 1) OR line_no = @line_no)	AND
									 order_no		= @order_no												AND  
									 order_ext		= @order_ext											AND  
									 location		= @location												AND
									 qty_ordered   <> qty_avail)										
						SET @frame_case_match = @frame_case_match + 1
					ELSE
						SET @frame_case_match = 0
												
				END
				--SELECT qty_ordered, qty_avail,* FROM #so_allocation_detail_view_Detail WHERE ((from_line_no = @line_no AND is_case = 1) OR line_no = @line_no)	AND								  order_no		= @order_no AND order_ext = @order_ext AND location = @location																					
				FETCH NEXT FROM temp_alloc_line_cur INTO @line_no, @part_no
			END
			CLOSE       temp_alloc_line_cur	
			DEALLOCATE  temp_alloc_line_cur		
		END     --sales order without allocation or packing				
		
		IF @frame_case_match = 0
			BEGIN
				INSERT INTO #so_alloc_management_Match
				SELECT  * FROM #so_alloc_management_Header WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location
				
				INSERT INTO #so_allocation_detail_view_Match
				SELECT  * FROM #so_allocation_detail_view_Detail WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location
			END
		ELSE
			BEGIN
				INSERT INTO #so_alloc_management_NO_match
				SELECT  * FROM #so_alloc_management_Header WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location
		
				INSERT INTO #so_allocation_detail_view_NO_match	
				SELECT  * FROM #so_allocation_detail_view_Detail WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location
			END

		
		FETCH NEXT FROM temp_orders_cur INTO @order_no, @order_ext, @location
	END --temp_orders_cur
    CLOSE      temp_orders_cur	
	DEALLOCATE temp_orders_cur
END
GO
GRANT EXECUTE ON  [dbo].[CVO_frame_case_match_sp] TO [public]
GO
