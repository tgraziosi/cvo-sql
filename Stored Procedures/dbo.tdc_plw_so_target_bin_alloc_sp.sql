SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_plw_so_target_bin_alloc_sp] @template_code varchar(20), @user_id varchar(50)
AS 

DECLARE @location	varchar(10),
	@part_no	varchar(30),
	@lot_ser	varchar(25),
	@bin_no		varchar(12),
	@qty		decimal(24,8),
	@date_expires   datetime

--------------------------------------------------------------------------------------------------------------------
---- Ensure Valid Data
--------------------------------------------------------------------------------------------------------------------
	UPDATE #so_target_bin_alloc_lot_bin SET qty_to_process = 0         WHERE qty_to_process < 0
	UPDATE #so_target_bin_alloc_lot_bin SET qty_to_process = qty_avail WHERE qty_to_process > qty_avail

--------------------------------------------------------------------------------------------------------------------
---- Header table
--------------------------------------------------------------------------------------------------------------------
	-- If there are no records in the header table, fill it
	IF NOT EXISTS(SELECT * FROM #so_target_bin_alloc_lot_bin)
	BEGIN
		INSERT INTO #so_target_bin_alloc_parts (location,  part_no,   qty_ordered, qty_picked,  
		                                        qty_alloc, qty_avail, qty_needed,  qty_to_process)
		SELECT a.location, a.part_no, SUM(a.qty_ordered), SUM(a.qty_picked), 
		       SUM(a.qty_alloc), 0, qty_needed = SUM(a.qty_ordered - a.qty_picked - a.qty_alloc), 0
		  FROM #so_allocation_detail_view a, 
		       #so_alloc_management       b
		 WHERE a.order_no    = b.order_no
		   AND a.order_ext   = b.order_ext
		   AND a.location    = b.location
		   AND b.sel_flg    != 0
                   AND a.lb_tracking = 'Y'
	 	 GROUP BY a.location, a.part_no 


		------------------------------------------------------------------------------------------
		-- Remove unwanted parts								--
		------------------------------------------------------------------------------------------
		IF EXISTS (SELECT * FROM tdc_part_filter_tbl(NOLOCK) 
			    WHERE alloc_filter = 'Y'
			      AND userid     = @user_id 
			      AND order_type = 'S') 
		BEGIN
			--use $$[]$$ as a token between location and part-no
			DELETE FROM #so_target_bin_alloc_parts
			 WHERE location + '$$[]$$' + part_no NOT IN (SELECT location + '$$[]$$' + part_no
								       FROM tdc_part_filter_tbl(NOLOCK) 
								      WHERE alloc_filter = 'Y'
								        AND userid       = @user_id 
								        AND order_type   = 'S')
			  
		END
	END
	ELSE
	--If there are records, update the table
	BEGIN 

		UPDATE #so_target_bin_alloc_parts 
		   SET qty_avail = (SELECT ISNULL((SELECT SUM(qty_avail)
						     FROM #so_target_bin_alloc_lot_bin
						    WHERE location = #so_target_bin_alloc_parts.location
						      AND part_no  = #so_target_bin_alloc_parts.part_no
						    GROUP BY location, part_no), 0)),
		       qty_needed = ((SELECT ISNULL((SELECT SUM(a.qty_ordered - a.qty_picked - a.qty_alloc)
						      FROM #so_allocation_detail_view a, 
						           #so_alloc_management       b
						     WHERE a.order_no  = b.order_no
						       AND a.order_ext = b.order_ext
						       AND a.location  = b.location
						       AND b.sel_flg  != 0
				                       AND a.lb_tracking = 'Y'
						       AND a.location = #so_target_bin_alloc_parts.location
						       AND a.part_no  = #so_target_bin_alloc_parts.part_no
					 	     GROUP BY a.location, a.part_no), 0))
				   - (SELECT ISNULL((SELECT SUM(qty_to_process)
						       FROM #so_target_bin_alloc_lot_bin
						      WHERE location 	    = #so_target_bin_alloc_parts.location
						        AND part_no  	    = #so_target_bin_alloc_parts.part_no
							AND qty_to_process >= 0), 0))),
		   qty_to_process  = (SELECT ISNULL((SELECT SUM(qty_to_process)
						       FROM #so_target_bin_alloc_lot_bin
						      WHERE location 	    = #so_target_bin_alloc_parts.location
						        AND part_no  	    = #so_target_bin_alloc_parts.part_no
							AND qty_to_process >= 0), 0))  
 
		UPDATE #so_target_bin_alloc_parts SET qty_needed = 0 WHERE qty_needed < 0 
	END 
 
--------------------------------------------------------------------------------------------------------------------
---- Detail table
--------------------------------------------------------------------------------------------------------------------
	IF NOT EXISTS(SELECT * FROM #so_target_bin_alloc_lot_bin)
	BEGIN
	
		DECLARE lot_bin_cur 
		 CURSOR FOR SELECT a.location, a.part_no, a.lot_ser, a.bin_no, a.date_expires, SUM(a.qty)
			      FROM lot_bin_stock  a (NOLOCK),
				   tdc_bin_master b (NOLOCK)
			     WHERE a.location 	     = b.location
			       AND a.bin_no   	     = b.bin_no	
			       AND b.usage_type_code = (SELECT bin_type 
							  FROM tdc_plw_process_templates c  (NOLOCK)
							 WHERE template_code = @template_code
							   AND userid        = @user_id
							   AND c.location    = a.location
							   AND order_type    = 'S'                    
							   AND type          = 'cons')  							  
			       AND a.location + '$$##$$' + a.part_no IN (SELECT location + '$$##$$' + part_no
								           FROM #so_target_bin_alloc_parts)
			     GROUP BY a.location, a.part_no, a.lot_ser, a.bin_no, a.date_expires
	
		OPEN lot_bin_cur
		FETCH NEXT FROM lot_bin_cur INTO @location, @part_no, @lot_ser, @bin_no, @date_expires, @qty
	
		WHILE @@FETCH_STATUS = 0
		BEGIN

		   	SELECT @qty = @qty - (SELECT ISNULL((SELECT SUM(qty)
							       FROM tdc_soft_alloc_tbl
							      WHERE location = @location
								AND lot_ser  = @lot_ser
								AND bin_no   = @bin_no
							        AND part_no  = @part_no),0))
			IF ISNULL(@qty, 0) > 0 
			BEGIN


				INSERT INTO #so_target_bin_alloc_lot_bin 
					(location, part_no, lot_ser, bin_no, date_expires, qty_avail, qty_to_process)
				VALUES (@location, @part_no, @lot_ser, @bin_no, @date_expires, @qty, 0 )
			END
	
			FETCH NEXT FROM lot_bin_cur INTO @location, @part_no, @lot_ser, @bin_no, @date_expires, @qty
		END
		CLOSE lot_bin_cur
		DEALLOCATE lot_bin_cur
	
		UPDATE #so_target_bin_alloc_parts 
		   SET qty_avail = (SELECT ISNULL((SELECT SUM(qty_avail)
						     FROM #so_target_bin_alloc_lot_bin
						    WHERE location = #so_target_bin_alloc_parts.location
						      AND part_no  = #so_target_bin_alloc_parts.part_no
						    GROUP BY location, part_no), 0))
 
		UPDATE #so_target_bin_alloc_parts SET qty_needed = 0 WHERE qty_needed < 0 
	END
	ELSE -- Make sure valid data
	BEGIN
		UPDATE #so_target_bin_alloc_lot_bin SET qty_to_process = 0 WHERE qty_to_process < 0		
	END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_target_bin_alloc_sp] TO [public]
GO
