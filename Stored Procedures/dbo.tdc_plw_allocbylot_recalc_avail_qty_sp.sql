SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_plw_allocbylot_recalc_avail_qty_sp]
			@location    	varchar(10),
			@part_no     	varchar(30),
			@entered_lot   	varchar(24),
			@entered_bin  	varchar(10),
			@required_qty	decimal(24,8)
AS

DECLARE	@lot_ser          	varchar(25),
        @bin_no           	varchar(12),
	@qty			decimal(24,8),
	@in_stock_qty		decimal(24,8),
	@allocated_qty		decimal(24,8),
	@available_qty		decimal(24,8),
	@mgtb2b_qty		decimal(24,8)

DECLARE recalc_cursor CURSOR FOR 
	SELECT lot_ser, bin_no, CASE WHEN sel_flg2 <> 0
		    		     THEN -qty 
		    		     ELSE qty
	       			END
	  FROM #plw_alloc_by_lot_bin 

OPEN recalc_cursor
FETCH NEXT FROM recalc_cursor INTO @lot_ser, @bin_no, @qty

WHILE (@@FETCH_STATUS <> -1)
BEGIN
	--1. Get in stock qty on the LOT/BIN
	SELECT @in_stock_qty = 0
	SELECT @in_stock_qty = qty
	  FROM lot_bin_stock (NOLOCK)
	 WHERE location = @location
           AND part_no  = @part_no
           AND bin_no   = @bin_no
           AND lot_ser  = @lot_ser

	--2. Get allocated qty for all the orders on the LOT/BIN
	SELECT @allocated_qty = 0
	SELECT @allocated_qty = SUM(qty)
	  FROM tdc_soft_alloc_tbl (NOLOCK)
	 WHERE location = @location
           AND part_no  = @part_no
           AND lot_ser  = @lot_ser
           AND bin_no   = @bin_no
	 GROUP BY location

	-- Get inventory for this part / location /lot / bin that a warehouse manager requested a MGTB2B move on.
	SELECT @mgtb2b_qty = 0
	SELECT @mgtb2b_qty =  SUM(qty_to_process)
	  FROM tdc_pick_queue (NOLOCK)
	 WHERE location = @location 
	   AND part_no  = @part_no 
	   AND lot      = @lot_ser 
	   AND bin_no   = @bin_no 
	   AND trans    = 'MGTBIN2BIN'
	 GROUP BY location

	SELECT @in_stock_qty = @in_stock_qty - @mgtb2b_qty  


	-- Calulate available qty for the LOT/BIN
	SELECT @available_qty = 0
	SELECT @available_qty = CASE
					WHEN @in_stock_qty - @allocated_qty - @qty < @required_qty
					THEN @in_stock_qty - @allocated_qty - @qty
					ELSE @required_qty
				END

	UPDATE #plw_alloc_by_lot_bin
	   SET avail_qty = @available_qty
         WHERE lot_ser = @lot_ser
	   AND bin_no  = @bin_no
 

	FETCH NEXT FROM recalc_cursor INTO @lot_ser, @bin_no, @qty
END

CLOSE 	   recalc_cursor
DEALLOCATE recalc_cursor

RETURN 
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_allocbylot_recalc_avail_qty_sp] TO [public]
GO
