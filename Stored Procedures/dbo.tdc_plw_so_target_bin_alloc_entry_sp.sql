SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_plw_so_target_bin_alloc_entry_sp]
	@location	varchar(10),
	@lot_ser	varchar(25),
	@bin_no		varchar(12),
	@part_no	varchar(30),
	@qty_entered    decimal(24,8),
	@err_msg	varchar(255) OUTPUT
AS

DECLARE @total_qty_to_process 			decimal(24,8),
	@qty_to_process_excluding_lot_bin 	decimal(24,8),
	@qty_needed				decimal(24,8),
	@qty_to_process				decimal(24,8),
	@qty_avail				decimal(24,8)

-------------------------------------------------------------------------------------------------------------------
--  Get the total qty to process
-------------------------------------------------------------------------------------------------------------------
SELECT @total_qty_to_process = SUM(qty_to_process)
  FROM #so_target_bin_alloc_lot_bin
 WHERE location = @location
   AND part_no  = @part_no

-------------------------------------------------------------------------------------------------------------------
--  Get the total qty to process MINUS the quantity entered
-------------------------------------------------------------------------------------------------------------------
SELECT @qty_to_process_excluding_lot_bin = ISNULL(@total_qty_to_process, 0) - ISNULL(qty_to_process, 0)
  FROM #so_target_bin_alloc_lot_bin
 WHERE location = @location
   AND lot_ser  = @lot_ser
   AND bin_no   = @bin_no
   AND part_no  = @part_no

-------------------------------------------------------------------------------------------------------------------
--  Get the total qty to process 
-------------------------------------------------------------------------------------------------------------------
SELECT @qty_to_process = ISNULL(@qty_to_process_excluding_lot_bin, 0) + @qty_entered

-------------------------------------------------------------------------------------------------------------------
--  Get the total qty needed
-------------------------------------------------------------------------------------------------------------------
SELECT @qty_needed =  SUM(a.qty_ordered - a.qty_picked - a.qty_alloc)
  FROM #so_allocation_detail_view a, 
       #so_alloc_management       b
 WHERE a.order_no  = b.order_no
   AND a.order_ext = b.order_ext
   AND a.location  = b.location
   AND b.sel_flg  != 0
   AND a.lb_tracking = 'Y'
   AND a.location = @location
   AND a.part_no  = @part_no
 GROUP BY a.location, a.part_no 

-------------------------------------------------------------------------------------------------------------------
--  Get the available quantity
-------------------------------------------------------------------------------------------------------------------
SELECT @qty_avail = qty_avail
  FROM #so_target_bin_alloc_lot_bin 
 WHERE location = @location
   AND part_no  = @part_no
   AND lot_ser  = @lot_ser
   AND bin_no   = @bin_no

-------------------------------------------------------------------------------------------------------------------
--  Test the values
-------------------------------------------------------------------------------------------------------------------
IF ISNULL(@qty_needed, 0) < ISNULL(@qty_to_process, 0)
BEGIN
	SELECT @err_msg = 'Quantity To Process is greater than Quantity Needed'
	RETURN -1
END

IF ISNULL(@qty_avail, 0) < ISNULL(@qty_entered, 0)
BEGIN
	SELECT @err_msg = 'Quantity To Process is greater than Quantity Available'
	RETURN -1
END

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_target_bin_alloc_entry_sp] TO [public]
GO
