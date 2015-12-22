SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_plw_sia_weighted_sp]
AS 

DECLARE @order_no int,
	@order_ext int, 
	@location varchar(10),
	@part_no varchar(30),
	@lb_tracking char(1),
	@total_ordered int,
	@qty_avail int,
	@qty_alloc int,
	@order_count int,
	@increment int,
	@ret int,
	@sch_ship_date datetime

SELECT @ret = -1

DECLARE sia_part_cur CURSOR FOR	
	SELECT DISTINCT location, part_no, lb_tracking
	  FROM #temp_sia_working_tbl b	
	 WHERE qty_needed > 0 
	   AND qty_needed > qty_to_alloc

OPEN sia_part_cur
FETCH NEXT FROM sia_part_cur INTO @location, @part_no, @lb_tracking

WHILE @@FETCH_STATUS = 0
BEGIN

	-- Get the quantity allocated to other orders
	SELECT @qty_alloc = 0
	SELECT @qty_alloc = SUM(CEILING(qty))
	  FROM tdc_soft_alloc_tbl(NOLOCK)
	 WHERE location = @location 
	   AND part_no = @part_no
 
	-- Determine the quantity available
	SELECT @qty_avail = 0
	IF @lb_tracking = 'Y'
	BEGIN
		SELECT @qty_avail = SUM(FLOOR(qty)) 
		  FROM lot_bin_stock a(NOLOCK),
		       tdc_bin_master b(NOLOCK)
		 WHERE a.location = @location
		   AND a.part_no = @part_no
		   AND a.location = b.location
		   AND a.bin_no = b.bin_no
		   AND b.usage_type_code IN('OPEN', 'REPLENISH')
	END
	ELSE
	BEGIN
		SELECT @qty_avail = SUM(FLOOR(in_stock)) 
		  FROM inventory(NOLOCK)
		 WHERE location = @location
		   AND part_no = @part_no
	END
 
	SELECT @qty_avail = ISNULL(@qty_avail, 0) - ISNULL(@qty_alloc, 0) 

	SELECT @qty_avail = @qty_avail - 
		ISNULL((SELECT CEILING(SUM(tp.pick_qty - tp.used_qty) )
		          FROM tdc_wo_pick tp(NOLOCK), 
		               prod_list pl(NOLOCK)   
		         WHERE tp.prod_no     = pl.prod_no 
			   AND tp.prod_ext    = pl.prod_ext
		           AND tp.location    = pl.location 
			   AND tp.part_no     = pl.part_no 
			   AND pl.status      < 'S' 
		           AND pl.lb_tracking = 'N' 
		           AND pl.location    = @location 
			   AND pl.part_no     = @part_no), 0)
 
	SELECT @qty_avail = @qty_avail - SUM(qty_to_alloc)
	  FROM #temp_sia_working_tbl
	 WHERE location = @location
	   AND part_no = @part_no		 

	-- Get the total amount ordered for this part
	SELECT @total_ordered = 0
	SELECT @total_ordered = SUM(qty_ordered)
	  FROM #temp_sia_working_tbl
	 WHERE location = @location 
	   AND part_no = @part_no	

	UPDATE #temp_sia_working_tbl	
	   SET qty_to_alloc = CASE WHEN qty_to_alloc + FLOOR(((CAST(qty_ordered AS DECIMAL) / CAST(@total_ordered AS DECIMAL))  * @qty_avail)- qty_assigned) <= qty_needed
				   THEN qty_to_alloc + FLOOR(((CAST(qty_ordered AS DECIMAL) / CAST(@total_ordered AS DECIMAL))  * @qty_avail)- qty_assigned)
				   ELSE qty_needed
			      END
	 WHERE location = @location
	   AND part_no = @part_no
	   AND qty_needed > qty_to_alloc
	   AND FLOOR(((CAST(qty_ordered AS DECIMAL) / CAST(@total_ordered AS DECIMAL))  * @qty_avail)- qty_assigned) > 0
 
 
	IF @@rowcount > 0
	BEGIN

		SELECT @ret = 0
	END
	ELSE
	BEGIN
		SELECT @order_count = COUNT(*)
		  FROM #temp_sia_working_tbl
		 WHERE location = @location
		   AND part_no = @part_no
		   AND qty_needed > qty_to_alloc
		SELECT @increment = CEILING(CAST(@qty_avail AS DECIMAL) / @order_count)
 
		DECLARE leftover_cur CURSOR FOR
		SELECT DISTINCT a.order_no, a.order_ext, b.sch_ship_date
		  FROM #temp_sia_working_tbl a, 
		       orders b(nolock),
		       ord_list c(nolock)
		 WHERE a.order_no = b.order_no
		   AND a.order_ext = b.ext
		   AND a.order_no = c.order_no
		   AND c.order_ext = c.order_ext
		   AND c.location = @location
		   AND a.part_no = c.part_No
		   AND a.part_no = @part_no
		   AND qty_needed > 0
		   AND qty_needed > qty_to_alloc
		 ORDER BY b.sch_ship_date
	
		OPEN leftover_cur
		FETCH NEXT FROM leftover_cur INTO @order_no, @order_ext, @sch_ship_date
	 
		WHILE @@FETCH_STATUS = 0 AND @qty_avail > 0
		BEGIN
			UPDATE #temp_sia_working_tbl	
			   SET qty_to_alloc = CASE WHEN (qty_to_alloc + @increment) >= qty_needed
						   THEN qty_needed
						   ELSE (qty_to_alloc + @increment)
						END
			 WHERE order_no = @order_no
			   AND order_ext = @order_ext
			   AND location = @location
			   AND part_no = @part_no
			   AND qty_needed > qty_to_alloc
			SELECT @qty_avail = @qty_avail - 1
				
			SELECT @ret = 0

			FETCH NEXT FROM leftover_cur INTO @order_no, @order_ext, @sch_ship_date
		END
	
		CLOSE leftover_cur
		DEALLOCATE leftover_cur
	END

	FETCH NEXT FROM sia_part_cur INTO @location, @part_no, @lb_tracking
END
CLOSE sia_part_cur
DEALLOCATE sia_part_cur
 
return @ret
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_sia_weighted_sp] TO [public]
GO
