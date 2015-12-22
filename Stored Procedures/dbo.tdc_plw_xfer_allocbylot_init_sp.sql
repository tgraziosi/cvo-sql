SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_plw_xfer_allocbylot_init_sp]
			@from_loc  	varchar(10),
			@part_no   	varchar(30),
			@xfer_no  	int,
			@line_no	int,
			@needed_qty 	decimal(20, 8),
			@template_code  varchar(15),
			@user_id	varchar(50)
AS

DECLARE	@lot_ser       		varchar(25),
        @bin_no        		varchar(12),
        @bin_group     		varchar(12),
	@inv_qty		decimal(20, 8),
	@avail_qty		decimal(20, 8),
	@alloc_qty_for_line_no	decimal(20, 8),
	@alloc_qty_total	decimal(20, 8),
	@alloc_qty_for_lot_bin  decimal(20, 8),
	@SQL			varchar(1000)

TRUNCATE TABLE #plw_alloc_by_lot_bin

------------------------------------------------------------------------------------------
-- Get the user's settings
------------------------------------------------------------------------------------------
SELECT @bin_group     = bin_group
  FROM tdc_plw_process_templates (NOLOCK)
 WHERE template_code  = @template_code
   AND UserID         = @user_id
   AND location       = @from_loc
   AND order_type     = 'X'
   AND type           = 'one4one'

-- Insert all the records from lot_bin_stock
SET @SQL =
	'INSERT INTO #plw_alloc_by_lot_bin(lot_ser, bin_no, date_expires, cur_alloc, avail_qty, sel_flg1, sel_flg2, qty)  
	 SELECT lb.lot_ser, lb.bin_no, CONVERT(varchar(12), date_expires, 101), 0, 0, 0, 0, 0
	   FROM lot_bin_stock              lb (NOLOCK), 
	        tdc_bin_master             bm (NOLOCK)
	  WHERE lb.location = ' + char(39) + @from_loc + char(39) + 
	'   AND lb.part_no  = ' + char(39) + @part_no  + char(39) +   
	'   AND lb.bin_no   = bm.bin_no
	    AND lb.location = bm.location
	    AND bm.usage_type_code IN (''OPEN'', ''REPLENISH'')'

IF ISNULL(@bin_group, '[ALL]') <> '[ALL]'
BEGIN
	SET @SQL = @SQL + ' AND bm.group_code = ''' + @bin_group + ''''
END

EXEC (@SQL)

-- Get allocated qty for the part/line_no 
SELECT @alloc_qty_for_line_no = 0
SELECT @alloc_qty_for_line_no = SUM(qty)
  FROM tdc_soft_alloc_tbl (NOLOCK)
 WHERE order_no   = @xfer_no
   AND order_ext  = 0
   AND order_type = 'T'
   AND location   = @from_loc
   AND line_no    = @line_no
   AND part_no    = @part_no
 GROUP BY location

-- Calculate needed qty for the part/line_no regardless LOTs/BINs
SELECT @needed_qty = @needed_qty - @alloc_qty_for_line_no

------------------------------------------------
-- Set currently allocated and available qty  --
------------------------------------------------
DECLARE alloc_qty_cursor CURSOR FOR 
	SELECT lot_ser, bin_no FROM #plw_alloc_by_lot_bin ORDER BY lot_ser

OPEN alloc_qty_cursor
FETCH NEXT FROM alloc_qty_cursor INTO @lot_ser, @bin_no

WHILE (@@FETCH_STATUS <> -1)
BEGIN
	-- Get allocated qty for the part/line_no on the lot/bin
	SELECT @alloc_qty_for_lot_bin = 0
	SELECT @alloc_qty_for_lot_bin = qty
	  FROM tdc_soft_alloc_tbl (NOLOCK)
	 WHERE order_no   = @xfer_no
           AND order_ext  = 0
 	   AND order_type = 'T'
	   AND location   = @from_loc
     	   AND line_no    = @line_no
     	   AND part_no    = @part_no
	   AND lot_ser    = @lot_ser
  	   AND bin_no     = @bin_no

	-- Get in stock qty for the part on the lot/bin
	SELECT @inv_qty = 0
	SELECT @inv_qty = qty
	  FROM lot_bin_stock (NOLOCK)
	 WHERE location = @from_loc
	   AND part_no  = @part_no
           AND bin_no   = @bin_no
           AND lot_ser  = @lot_ser	

	-- Get allocated qty for the part on the lot/bin regardless order_no
	SELECT @alloc_qty_total = 0
	SELECT @alloc_qty_total = SUM(qty)
	  FROM tdc_soft_alloc_tbl (NOLOCK)
	 WHERE location   = @from_loc
     	   AND part_no    = @part_no
	   AND lot_ser    = @lot_ser
  	   AND bin_no     = @bin_no
 	 GROUP BY location

	-- Calculate available qty
	SELECT @avail_qty = 0
	SELECT @avail_qty = CASE 
				WHEN @needed_qty = 0 
				THEN 0
				ELSE CASE
					WHEN @inv_qty - @alloc_qty_total >= @needed_qty THEN @needed_qty
					WHEN @inv_qty - @alloc_qty_total <  @needed_qty THEN @inv_qty - @alloc_qty_total
				     END
			    END

	UPDATE #plw_alloc_by_lot_bin  
	   SET cur_alloc = @alloc_qty_for_lot_bin,
	       avail_qty = @avail_qty
	 WHERE lot_ser   = @lot_ser
	   AND bin_no    = @bin_no

	FETCH NEXT FROM alloc_qty_cursor INTO @lot_ser, @bin_no
END

CLOSE      alloc_qty_cursor
DEALLOCATE alloc_qty_cursor

RETURN 
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_xfer_allocbylot_init_sp] TO [public]
GO
