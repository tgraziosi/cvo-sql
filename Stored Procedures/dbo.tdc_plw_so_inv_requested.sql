SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_plw_so_inv_requested]
AS

DECLARE @location 			varchar(10),
	@part_no			varchar(30),
	@qty_ordered			decimal(24,8),
	@qty_in_stock			decimal(24,8),	
	@qty_alloc_for_part_line_no	decimal(24,8),
	@qty_avail_in_replen		decimal(24,8)


-----------------------------------------------------------------------------------------------------------------
-- 0) Bin View Grid
-----------------------------------------------------------------------------------------------------------------
BEGIN
 
	TRUNCATE TABLE #so_inv_requested

	INSERT INTO #so_inv_requested(location,  part_no,    qty_ordered, qty_avail, 
				       avail_pct, replen_qty, replen_pct)

	SELECT b.location, a.part_no, SUM(a.qty_ordered), SUM(a.qty_avail), 
		curr_fill_pct = CASE WHEN SUM(a.qty_avail) = 0 
					THEN 0
				     WHEN SUM(a.qty_avail) >= SUM(a.qty_ordered) 
					THEN 100
				     ELSE 100 * SUM(a.qty_avail) / SUM(a.qty_ordered)
				END, 
		0, 0
	  FROM  #so_allocation_detail_view a , 
	        #so_alloc_management       b
         WHERE  b.sel_flg  != 0 
           AND  b.order_no  = a.order_no 
	   AND  b.order_ext = a.order_ext
	   AND  b.location  = a.location
	   AND  a.lb_tracking = 'Y'
	 GROUP BY  b.location, a.part_no, b.curr_fill_pct

	-----------------------------------------------------------------------------------------------------------------
	-- Loop through the temp table and 
	-----------------------------------------------------------------------------------------------------------------
	DECLARE part_cursor CURSOR FOR
		SELECT location, part_no, qty_ordered 
		  FROM #so_inv_requested (NOLOCK)
		 ORDER BY location, part_no, qty_ordered
	         
	OPEN part_cursor 

	FETCH NEXT FROM part_cursor INTO @location, @part_no, @qty_ordered
		

	WHILE (@@FETCH_STATUS = 0)
	BEGIN 	
           	-- Qty in stock for part location 
		SELECT @qty_in_stock = 0
		SELECT @qty_in_stock = SUM(qty) 
  	          FROM lot_bin_stock  a (NOLOCK), 
		       tdc_bin_master b (NOLOCK) 
                 WHERE a.location 	 = @location 
		   AND a.part_no  	 = @part_no 	   	           
   		   AND a.bin_no   	 = b.bin_no 
   		   AND a.location 	 = b.location 
   		   AND b.usage_type_code = 'REPLENISH'
	         GROUP BY a.part_no


       		-- Qty already allocated  
		SELECT @qty_alloc_for_part_line_no = 0
		SELECT  @qty_alloc_for_part_line_no = SUM(a.qty)
		  FROM tdc_soft_alloc_tbl a (NOLOCK),
		       tdc_bin_master b (NOLOCK)	
		 WHERE a.order_no	!= 0
		   AND a.part_no   	 = @part_no 
		   AND a.order_type 	 = 'S'
		   AND a.location   	 = @location
		   AND a.target_bin  	 = b.bin_no
		   AND ((a.lot_ser  	!= 'CDOCK' AND a.bin_no != 'CDOCK') 
		    OR  (a.lot_ser  	 IS NULL   AND a.bin_no IS NULL))								
		   AND b.usage_type_code = 'REPLENISH'
		 GROUP BY a.location
		
		-- Qty avail in replenish
		SELECT @qty_avail_in_replen = 0
		IF ((@qty_in_stock - @qty_alloc_for_part_line_no ) <  @qty_ordered )
			IF @qty_in_stock > @qty_alloc_for_part_line_no
				SELECT @qty_avail_in_replen = @qty_in_stock - @qty_alloc_for_part_line_no
			ELSE
				SELECT @qty_avail_in_replen = 0 
		ELSE
			SELECT @qty_avail_in_replen = @qty_ordered

		UPDATE #so_inv_requested 
		   SET replen_qty = @qty_avail_in_replen ,
		       replen_pct = 100 * (@qty_avail_in_replen / ISNULL(@qty_ordered,0) )
		 WHERE location   = @location
		   AND part_no    = @part_no 

	
		FETCH NEXT FROM part_cursor INTO @location, @part_no, @qty_ordered
	END
	
	CLOSE      part_cursor 
	DEALLOCATE part_cursor 
END

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_inv_requested] TO [public]
GO
