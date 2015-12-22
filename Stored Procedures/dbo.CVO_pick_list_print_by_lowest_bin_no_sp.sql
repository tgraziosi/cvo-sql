SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[CVO_pick_list_print_by_lowest_bin_no_sp]    Script Date: 08/23/2010  *****
SED009 -- Pick List Printing
Object:      Procedure  CVO_pick_list_print_by_lowest_bin_no_sp  
Source file: CVO_pick_list_print_by_lowest_bin_no_sp.sql
Author:		 Jesus Velazquez
Created:	 08/23/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  

v1.1 CT 17/08/2012 - total pieces should be total qty allocated for the order
*/
CREATE PROCEDURE [dbo].[CVO_pick_list_print_by_lowest_bin_no_sp]
	
AS

BEGIN

	DECLARE @order_no INT, @order_ext INT

	DECLARE orders_cursor CURSOR FOR 
	SELECT order_no, order_ext FROM #so_pick_ticket_details --WHERE sel_flg <> 0 

	OPEN orders_cursor

	FETCH NEXT FROM orders_cursor 
	INTO @order_no, @order_ext

	WHILE @@FETCH_STATUS = 0
	BEGIN
	                
		UPDATE #so_pick_ticket_details
		SET    lowest_bin_no = (SELECT  ISNULL(MIN(bin_no),'')
								FROM    tdc_soft_alloc_tbl (NOLOCK) 
								WHERE   order_no  = @order_no AND order_ext = @order_ext) 
							    
			  ,highest_bin_no = (SELECT ISNULL(MAX(bin_no),'')
								 FROM   tdc_soft_alloc_tbl (NOLOCK) 
								 WHERE  order_no  = @order_no AND order_ext = @order_ext)
		WHERE  order_no  = @order_no AND 
		       order_ext = @order_ext		       		       
		 
		-- START v1.1
		UPDATE  #so_pick_ticket_details   
		SET		total_pieces  = (SELECT CAST(SUM(qty) AS INT) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		WHERE	order_no  = @order_no	AND 
				order_ext = @order_ext		       

		/*
		UPDATE  #so_pick_ticket_details   
		SET		total_pieces  = (SELECT COUNT(DISTINCT line_no) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		WHERE	order_no  = @order_no	AND 
				order_ext = @order_ext		       
		*/
		-- END v1.1

	FETCH NEXT FROM orders_cursor 
	INTO @order_no, @order_ext
	END

	CLOSE orders_cursor
	DEALLOCATE orders_cursor

END
GO
GRANT EXECUTE ON  [dbo].[CVO_pick_list_print_by_lowest_bin_no_sp] TO [public]
GO
