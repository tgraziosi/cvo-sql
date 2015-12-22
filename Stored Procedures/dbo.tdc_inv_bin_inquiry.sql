SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_inv_bin_inquiry] AS

	TRUNCATE TABLE #out_stock_list

	BEGIN	
		INSERT INTO #out_stock_list ([description], lot_ser, part_no, qty)
			SELECT  i.[description], b.lot_ser, b.part_no, b.qty  
					    FROM inv_master i, lot_bin_stock b, #int_list_in t
			                    WHERE t.bin_no = b.bin_no
				            AND b.location = t.location 
					    AND i.part_no = b.part_no 
	END
	

GO
GRANT EXECUTE ON  [dbo].[tdc_inv_bin_inquiry] TO [public]
GO
