SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_backup_order_records_sp](@order_no int, @order_ext int)
WITH ENCRYPTION
AS
/*
	INSERT INTO tdc_bkp_dist_item_pick (method,order_no,order_ext,line_no,part_no,lot_ser,bin_no,quantity,
										child_serial_no,[function],type,status,bkp_status,bkp_date) 
			SELECT method,order_no,order_ext,line_no,part_no,lot_ser,bin_no,
										quantity,child_serial_no,[function],type,status, 'C', GETDATE()
                                    From tdc_dist_item_pick
                                    WHERE order_no = @order_no AND order_ext = @order_ext AND [function] = 'S'
	DELETE FROM tdc_dist_item_pick WHERE order_no = @order_no AND order_ext = @order_ext AND [function] = 'S'

	INSERT INTO tdc_bkp_ord_list_kit (order_no,order_ext,part_no,line_no,ordered,picked,location,
									  kit_part_no,sub_kit_part_no,qty_per_kit,kit_picked,bkp_status,bkp_date)
	   SELECT order_no,order_ext,part_no,line_no,ordered,picked,location,
											   kit_part_no,sub_kit_part_no,qty_per_kit,kit_picked, 'C', GETDATE()
                                    From tdc_ord_list_kit
                                    WHERE order_no = @order_no AND order_ext = @order_ext
	DELETE FROM tdc_ord_list_kit WHERE order_no = @order_no AND order_ext = @order_ext

	INSERT INTO tdc_bkp_dist_item_list (order_no,order_ext,line_no,part_no,quantity,shipped,
										[function],bkp_status,bkp_date) 
			SELECT order_no,order_ext,line_no,part_no,quantity,shipped,[function], 'C', GETDATE()
                                    From tdc_dist_item_list
                                    WHERE order_no = @order_no AND order_ext = @order_ext AND [function] = 'S'
	DELETE FROM tdc_dist_item_list WHERE order_no = @order_no AND order_ext = @order_ext AND [function] = 'S'

	EXEC tdc_set_status @order_no, @order_ext, 'R1'
*/
GO
GRANT EXECUTE ON  [dbo].[tdc_backup_order_records_sp] TO [public]
GO
