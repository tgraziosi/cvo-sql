SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_remove_cons_ords_sp]
@current_con_no 	int,
@user_id 		varchar(50)
AS
 
DECLARE @order_no 		int,
	@order_ext 		int,
	@con_no_from_temp_table int,
	@seq_no 		int ,
	@location 		varchar(12),
	@con_name		varchar(255),
	@con_desc		varchar(255) 

--Initialize seq no
SELECT @seq_no = 0

DECLARE order_selection_cursor CURSOR FOR
	SELECT a.order_no, a.order_ext, a.location, a.consolidation_no 
	  FROM #so_alloc_management a,
	       orders b(NOLOCK)	
	 WHERE a.sel_flg2 <> 0
	   AND a.order_no = b.order_no
	   AND a.order_ext = b.ext
	   AND b.status = 'N'

OPEN order_selection_cursor
FETCH NEXT FROM order_selection_cursor INTO @order_no, @order_ext, @location, @con_no_from_temp_table

WHILE (@@FETCH_STATUS = 0)
BEGIN	
	---------------------------------------------------------------------------------------------------------------
	----   If removing from set, delete from tdc_cons_ords							-------
	---------------------------------------------------------------------------------------------------------------
	--check to make sure the user is some how getting an order already assigned
	IF @con_no_from_temp_table <> 0 
	BEGIN
		DELETE tdc_cons_ords 
		 WHERE  consolidation_no = @current_con_no
		   AND  order_no         = @order_no
		   AND  order_ext        = @order_ext 
		   AND  location	 = @location
		   AND  order_type  	 = 'S'
		
		INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans,tran_no , tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
		VALUES(getdate(), @user_id , 'VB', 'PLW' , 'UnAllocation', @current_con_no, 0, '', '', '', @location, '', 'REMOVE order number = ' + CONVERT(VARCHAR(10),@order_no) + '-' + CONVERT(VARCHAR(10),@order_ext))			
	END

	FETCH NEXT FROM order_selection_cursor INTO @order_no, @order_ext, @location, @con_no_from_temp_table

END
CLOSE order_selection_cursor
DEALLOCATE order_selection_cursor

IF NOT EXISTS(SELECT * FROM tdc_cons_ords WHERE consolidation_no = @current_con_no)
	DELETE tdc_cons_filter_set 
	 WHERE consolidation_no = @current_con_no

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_remove_cons_ords_sp] TO [public]
GO
