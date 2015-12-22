SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_inv_inquiry] AS

	TRUNCATE TABLE #out_stock_list

	IF EXISTS ( SELECT i.lb_tracking FROM inv_master i, #int_list_in t 
		                         WHERE i.lb_tracking = 'Y' AND t.part_no = i.part_no)
	BEGIN	
		INSERT INTO #out_stock_list ( [description], lot_ser, bin_no, qty)
			SELECT  i.[description], b.lot_ser, b.bin_no, b.qty  
					    FROM inv_master i, lot_bin_stock b, #int_list_in t
			                    WHERE i.lb_tracking = 'Y' 
					    AND i.part_no = b.part_no 
				            AND b.location = t.location 
					    AND t.part_no = b.part_no
	END
	ELSE
	BEGIN
		INSERT INTO #out_stock_list  ( [description], lot_ser, bin_no, qty)
			SELECT i.[description],NULL, NULL, l.in_stock
					     FROM inv_master i, inventory l, #int_list_in t
					     WHERE i.lb_tracking = 'N' 
					     AND i.part_no = l.part_no 
                                             AND l.location = t.location 
					     AND l.part_no = t.part_no
	END

GO
GRANT EXECUTE ON  [dbo].[tdc_inv_inquiry] TO [public]
GO
