SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pre_pack_sp]
	@user_id		varchar(50),
	@station_id		varchar(3),
	@pkg_code		varchar(15),
	@pack_type		varchar(25),
	@overfill_or_adh_qty	decimal(24,8),
	@mix_parts_flag		char(1) = 'Y' 
AS

DECLARE @order_no		int, 
	@order_ext		int, 
	@carton_no		int,
	@location		varchar(15),
	@lot_ser		varchar(25),
	@line_no		int,
	@con_no			int,
	@part_no		varchar(30),
	@qty_alloc		decimal(24,8),
	@pack_qty		decimal(24,8),
	@qty_remain		decimal(24,8),
	@carton_qty		decimal(24,8),
	@completed_carton_qty	decimal(24,8),
	@carton_index		int,
	@I			int,
	@err_msg		varchar(255)
	
TRUNCATE TABLE #pre_pack_parts
TRUNCATE TABLE #pre_pack_cartons


---------------------------------------------------------------------------------------------------------------
-- If packing has started on any cartons for this order, ext, location raise an error
---------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * 
	    FROM tdc_carton_detail_tx     a (NOLOCK),
       	         #pre_pack_plan_order_sel b (NOLOCK),
                 ord_list		  c (NOLOCK)
	   WHERE b.order_no  = a.order_no
	     AND b.order_ext = a.order_ext
	     AND b.sel_flg  != 0
	     AND b.order_no  = c.order_no
	     AND b.order_ext = c.order_ext
	     AND b.location  = c.location
	     AND a.line_no   = c.line_no
	     AND a.pack_qty  > 0)
BEGIN
	  SELECT TOP 1 @order_no  = c.order_no,
		       @order_ext = c.order_ext,
		       @location  = c.location
	    FROM tdc_carton_detail_tx     a (NOLOCK),
       	         #pre_pack_plan_order_sel b (NOLOCK),
                 ord_list		  c (NOLOCK)
	   WHERE b.order_no  = a.order_no
	     AND b.order_ext = a.order_ext
	     AND b.sel_flg  != 0
	     AND b.order_no  = c.order_no
	     AND b.order_ext = c.order_ext
	     AND b.location  = c.location
	     AND a.line_no   = c.line_no
	     AND a.pack_qty  > 0

	SELECT @ERR_MSG = 'Packing has already started for order' + CHAR(13) + 
			  'Order:    ' + CAST(@order_no AS VARCHAR(20)) + '-' + CAST(@order_ext AS VARCHAR(10)) + CHAR(13) +
			  'Location: ' + @location
	RAISERROR (@err_msg, 16, 1)
	RETURN
END


---------------------------------------------------------------------------------------------------------------
-- Store the carton numbers you are deleting into a temp table
---------------------------------------------------------------------------------------------------------------
INSERT INTO #pre_pack_del_cartons (carton_no)
    SELECT DISTINCT tdc_carton_detail_tx.carton_no   
      FROM tdc_carton_detail_tx,
           tdc_carton_tx,
           #pre_pack_plan_order_sel,
           ord_list
 WHERE #pre_pack_plan_order_sel.order_no  = tdc_carton_detail_tx.order_no
   AND #pre_pack_plan_order_sel.order_ext = tdc_carton_detail_tx.order_ext
   AND #pre_pack_plan_order_sel.sel_flg  != 0
   AND #pre_pack_plan_order_sel.order_no  = ord_list.order_no
   AND #pre_pack_plan_order_sel.order_ext = ord_list.order_ext
   AND #pre_pack_plan_order_sel.location  = ord_list.location
   AND tdc_carton_detail_tx.line_no       = ord_list.line_no
   AND tdc_carton_tx.carton_no		  = tdc_carton_detail_tx.carton_no
   AND tdc_carton_tx.status       	  = 'P'
   AND tdc_carton_detail_tx.pack_qty      = 0


---------------------------------------------------------------------------------------------------------------
-- Clear the carton tables for this order, ext, location
---------------------------------------------------------------------------------------------------------------
DELETE FROM tdc_carton_detail_tx  
 WHERE carton_no IN(SELECT carton_no FROM #pre_pack_del_cartons)

DELETE FROM tdc_carton_tx
 WHERE carton_no IN(SELECT carton_no FROM #pre_pack_del_cartons)
 
 
---------------------------------------------------------------------------------------------------------------
-- Fill a temp table with parts needed to pre pack
---------------------------------------------------------------------------------------------------------------
IF @pkg_code = '[DEFAULT]' AND @pack_type != 'ADHOC'
BEGIN
	INSERT INTO #pre_pack_parts
		(order_no, order_ext, location, lot_ser, line_no, part_no, qty_alloc, pack_qty)
	SELECT a.order_no, a.order_ext, a.location, a.lot_ser, a.line_no, a.part_no, SUM(a.qty),
		CASE @pack_type WHEN 'CASE' 	THEN b.case_qty
				WHEN 'MAX-PACK'	THEN b.pack_qty
				WHEN 'PALLET'	THEN b.pallet_qty
				WHEN 'ADHOC'	THEN @overfill_or_adh_qty
		END
	  FROM tdc_soft_alloc_tbl 	a (NOLOCK),
	       tdc_inv_list	  	b (NOLOCK),
	       #pre_pack_plan_order_sel	c (NOLOCK)
	 WHERE a.order_no   = c.order_no
	   AND a.order_ext  = c.order_ext
	   AND a.order_type = 'S' 
	   AND a.location   = c.location
	   AND ISNULL(a.bin_no, '') = ISNULL(a.target_bin, '')
	   AND b.location   = c.location
	   AND b.part_no    = a.part_no
	   AND c.sel_flg   != 0
	 GROUP BY a.order_no, a.order_ext, a.location, a.lot_ser, a.line_no, a.part_no, b.case_qty, b.pack_qty, b.pallet_qty
END
ELSE IF @pkg_code != '[DEFAULT]' AND @pack_type != 'ADHOC'
BEGIN
	INSERT INTO #pre_pack_parts
		(order_no, order_ext, location, lot_ser, line_no, part_no, qty_alloc, pack_qty)
	SELECT a.order_no, a.order_ext, a.location, a.lot_ser, a.line_no, a.part_no, SUM(a.qty), b.pack_qty
	  FROM tdc_soft_alloc_tbl 	a (NOLOCK),
	       tdc_package_part	  	b (NOLOCK),
	       #pre_pack_plan_order_sel	c (NOLOCK)
	 WHERE a.order_no   = c.order_no
	   AND a.order_ext  = c.order_ext
	   AND a.order_type = 'S' 
	   AND a.location   = c.location
	   AND ISNULL(a.bin_no, '') = ISNULL(a.target_bin, '')
	   AND b.location   = c.location
	   AND b.part_no    = a.part_no
	   AND c.sel_flg   != 0
	 GROUP BY a.order_no, a.order_ext, a.location, a.lot_ser, a.line_no, a.part_no, b.pack_qty 

END
ELSE IF @pack_type = 'ADHOC'
BEGIN
 
	INSERT INTO #pre_pack_parts
		(order_no, order_ext, location, lot_ser, line_no, part_no, qty_alloc, pack_qty)
	SELECT a.order_no, a.order_ext, a.location, a.lot_ser, a.line_no, a.part_no, SUM(a.qty), @overfill_or_adh_qty
	  FROM tdc_soft_alloc_tbl 	a (NOLOCK),
	       #pre_pack_plan_order_sel	b (NOLOCK)
	 WHERE a.order_no   = b.order_no
	   AND a.order_ext  = b.order_ext
	   AND a.order_type = 'S' 
	   AND a.location   = b.location
	   AND ISNULL(a.bin_no, '') = ISNULL(a.target_bin, '')
	   AND b.sel_flg   != 0
	 GROUP BY a.order_no, a.order_ext, a.location, a.lot_ser, a.line_no, a.part_no 



END
 
---------------------------------------------------------------------------------------------------------------

--If only one part on the order, don't use the overfill qty unless adhoc
IF @pack_type != 'ADHOC'
BEGIN
	IF (SELECT COUNT(DISTINCT part_no)
	      FROM #pre_pack_parts) = 1 
	BEGIN
		SELECT @overfill_or_adh_qty = 0
	END
END

 
SELECT @carton_index = 0

DECLARE orders_cur 
 CURSOR FOR 
	SELECT order_no, order_ext, location, con_no
	  FROM #pre_pack_plan_order_sel
	 WHERE sel_flg <> 0
	 ORDER BY order_no, order_ext, location

OPEN orders_cur
FETCH NEXT FROM orders_cur INTO @order_no, @order_ext, @location, @con_no
WHILE @@FETCH_STATUS = 0
BEGIN

	DECLARE parts_cur
	 CURSOR FOR 
		SELECT lot_ser, line_no, part_no, qty_alloc, pack_qty 
		  FROM #pre_pack_parts
		 WHERE order_no  = @order_no
		   AND order_ext = @order_ext
		   AND location  = @location
		 ORDER BY line_no, part_no

	OPEN parts_cur
	FETCH NEXT FROM parts_cur INTO @lot_ser, @line_no, @part_no, @qty_alloc, @pack_qty
	WHILE @@FETCH_STATUS = 0
	BEGIN

		---------------------------------------------------------------------------------------------------------------
		-- Subtract the quantites that are already in cartons 
		---------------------------------------------------------------------------------------------------------------
		IF EXISTS(SELECT * 
			    FROM tdc_carton_detail_tx a,
		                 tdc_carton_tx b
			   WHERE a.order_no   = @order_no
			     AND a.order_ext  = @order_ext
			     AND a.line_no    = @line_no
			     AND a.carton_no  = b.carton_no
			     AND b.order_type = 'S')
		BEGIN
			SELECT @qty_alloc = @qty_alloc - SUM(a.qty_to_pack)
			  FROM tdc_carton_detail_tx a,
			       tdc_carton_tx b
			 WHERE a.order_no   = @order_no
			   AND a.order_ext  = @order_ext
			   AND a.line_no    = @line_no
			   AND a.carton_no  = b.carton_no
			   AND b.order_type = 'S'
		END


		--If adhoc, over-ride the pack_qty with the adhoc qty
		IF @pack_type = 'ADHOC'
			SELECT @pack_qty = @overfill_or_adh_qty

		--Determine the number of times the pack quantity will 
		--Go into the allocated quantity 
		IF @qty_alloc > @pack_qty
			SELECT @completed_carton_qty = (FLOOR(@qty_alloc / @pack_qty))
		ELSE
			SELECT @completed_carton_qty = 0

		---------------------------------------------------------------------------------------------------------------
		-- Insert all of the parts that will COMPLETELY fill carton(s)
		---------------------------------------------------------------------------------------------------------------
		SELECT @I = 0

		WHILE @I < @completed_carton_qty
		BEGIN

			INSERT INTO #pre_pack_cartons
				(carton_index, order_no, order_ext, location, con_no, lot_ser, line_no, part_no, pack_qty, qty)
			VALUES (@carton_index, @order_no, @order_ext, @location, @con_no, @lot_ser, @line_no, @part_no, @pack_qty, @pack_qty)

			SELECT @carton_index = @carton_index + 1
			SELECT @I = @I + 1
		END


		---------------------------------------------------------------------------------------------------------------
		-- Insert / Update the remaining parts
		---------------------------------------------------------------------------------------------------------------
		IF @qty_alloc >= (@pack_qty * @completed_carton_qty)
		BEGIN
			SELECT @qty_remain = @qty_alloc - (@pack_qty * @completed_carton_qty)

			---------------------------------------------------------------------------------------------------------------
			-- If there are parts left over, insert them into a new carton
			---------------------------------------------------------------------------------------------------------------				
			IF @overfill_or_adh_qty > 0  
			BEGIN
				WHILE @qty_remain > @overfill_or_adh_qty
				BEGIN		
					INSERT INTO #pre_pack_cartons
						(carton_index, order_no, order_ext, location, con_no, lot_ser, line_no, part_no, pack_qty, qty)
					VALUES (@carton_index, @order_no, @order_ext, @location, @con_no, @lot_ser, @line_no, @part_no, @pack_qty, @overfill_or_adh_qty)

					SELECT @carton_index = @carton_index + 1
					SELECT @qty_remain = @qty_remain - @overfill_or_adh_qty
				END
			END
			IF @qty_remain > 0 
			BEGIN		

				SELECT @carton_no = NULL
				SELECT TOP 1 @carton_no = carton_index
				  FROM #pre_pack_cartons
				 WHERE order_no = @order_no
				   AND order_ext = @order_ext
				   AND part_no   = @part_no
				 GROUP BY carton_index
				 HAVING (@pack_qty - SUM(qty)) >= @qty_remain
				 
				IF ISNULL(@carton_no, -1) != -1
				BEGIN
					INSERT INTO #pre_pack_cartons
						(carton_index, order_no, order_ext, location, con_no, lot_ser, line_no, part_no, pack_qty, qty)
					VALUES (@carton_no, @order_no, @order_ext, @location, @con_no, @lot_ser, @line_no, @part_no, @pack_qty, @qty_remain)
				END
				ELSE
				BEGIN
					INSERT INTO #pre_pack_cartons
						(carton_index, order_no, order_ext, location, con_no, lot_ser, line_no, part_no, pack_qty, qty)
					VALUES (@carton_index, @order_no, @order_ext, @location, @con_no, @lot_ser, @line_no, @part_no, @pack_qty, @qty_remain)
					
					SELECT @carton_index = @carton_index + 1
				END
				SELECT @qty_remain = 0
			END --@qty_remain > 0
 			

		END --(@qty_alloc - @completed_carton_qty) >= 0


		FETCH NEXT FROM parts_cur INTO @lot_ser, @line_no, @part_no, @qty_alloc, @pack_qty
	END -- Parts_cur WHILE

	CLOSE parts_cur
	DEALLOCATE parts_cur

	FETCH NEXT FROM orders_cur INTO @order_no, @order_ext, @location, @con_no
END -- Orders_cur WHILE

CLOSE orders_cur
DEALLOCATE orders_cur


---------------------------------------------------------------------------------------------------------------
-- If mixing parts, execute the mix-parts stored procedure
---------------------------------------------------------------------------------------------------------------
IF @mix_parts_flag = 'Y'
	EXEC tdc_pre_pack_mix_parts_sp @overfill_or_adh_qty

DECLARE insert_cartons_cur
 CURSOR FOR
	SELECT DISTINCT carton_index
	  FROM #pre_pack_cartons
	 ORDER BY carton_index

OPEN insert_cartons_cur
FETCH NEXT FROM insert_cartons_cur INTO @carton_index

WHILE @@FETCH_STATUS = 0
BEGIN
	
	SELECT @order_no  	= order_no,
	       @order_ext 	= order_ext,
	       @location  	= location,
	       @con_no		= con_no
	  FROM #pre_pack_cartons	
	 WHERE carton_index = @carton_index

	----------------------------------------------------------------------------------------------------------
	-- If there are still cartons from the deleted cartons table, use them.  Otherwise, generate new ones.
	----------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT * FROM #pre_pack_del_cartons)
	BEGIN
		SELECT TOP 1 @carton_no = carton_no
		  FROM #pre_pack_del_cartons
		 ORDER BY carton_no

		DELETE FROM #pre_pack_del_cartons
		 WHERE carton_no = @carton_no
	END
	ELSE
	begin
		EXEC @carton_no = tdc_get_serialno
	end

	IF @carton_no = -1
	BEGIN
		RAISERROR('Unable to generate next carton number', 16, 1)
		RETURN -1
	END

	INSERT INTO tdc_carton_tx (order_no, order_ext, carton_no, carton_type, carton_class, cust_code, cust_po, 
                carrier_code, shipper, ship_to_no, [name], address1, address2, address3, city, state, zip, 
                country, attention, date_shipped, weight, weight_uom, cs_tx_no, cs_tracking_no, cs_zone, 
                cs_oversize, cs_call_tag_no, cs_airbill_no, cs_other, cs_pickup_no, cs_dim_weight, 
                cs_published_freight, cs_disc_freight, cs_estimated_freight, cust_freight, freight_to, 
                adjust_rate, template_code, operator, consolidated_pick_no, void, status, station_id, 
                charge_code, bill_to_key, last_modified_date, modified_by, order_type, stlbin_no, stl_status)      
	SELECT @order_no, @order_ext, @carton_no, NULL, NULL, o.cust_code, o.cust_po, o.routing, '',  
                o.ship_to, o.ship_to_name, o.ship_to_add_1, o.ship_to_add_2,  
                o.ship_to_add_3, o.ship_to_city, o.ship_to_state,  
                o.ship_to_zip, o.ship_to_country, o.attention, o.date_shipped, 0, 'LB',  
                '', '', NULL, '', '', NULL, NULL, '', NULL, NULL, NULL, NULL,  
                NULL, o.freight_to, NULL , '',@user_id, @con_no, '0',  
                'P', @station_id, o.freight_allow_type, o.bill_to_key, getdate(), @user_id,  
                'S', '', 'N' 
      	 FROM orders o 
      	WHERE o.order_no =  @order_no
      	  AND o.ext = @order_ext        

		IF @@ERROR <> 0
		RAISERROR('Insert into tdc_carton_tx failed.', 16, 1)

	INSERT INTO tdc_carton_detail_tx (order_no, order_ext, carton_no, tx_date, line_no,
					  part_no, price, lot_ser, rec_date, bom_line_no,void, 
					  pack_qty, serial_no, status, version_no, tran_num, 
					  warranty_track, serial_no_raw, qty_to_pack, pack_tx)
	SELECT @order_no, @order_ext, @carton_no, GETDATE(), a.line_no,
	       a.part_no, 0, a.lot_ser, GETDATE(), NULL, NULL, 
	       0, NULL, 'P', NULL, NULL, 0, NULL, SUM(a.qty), 'PrePack'
	  FROM #pre_pack_cartons a
	 WHERE a.carton_index = @carton_index
	 GROUP BY a.line_no, a.part_no, a.lot_ser

		IF @@ERROR <> 0
		RAISERROR('Insert into tdc_carton_detail_tx failed.', 16, 1)
	FETCH NEXT FROM insert_cartons_cur INTO @carton_index
END

CLOSE insert_cartons_cur
DEALLOCATE insert_cartons_cur

RETURN

GO
GRANT EXECUTE ON  [dbo].[tdc_pre_pack_sp] TO [public]
GO
