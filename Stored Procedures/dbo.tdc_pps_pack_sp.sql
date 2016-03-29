
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 27/06/2012 - If the order has a global ship to then use the carrier from the global ship to
-- v1.1 CT 06/08/2012 - Remove changes made in v1.0
-- v1.2 CB 18/09/2014 - #572 Masterpack - Third Party Ship To 
-- v1.3 CB 23/04/2015 - Performance Changes
-- v1.4 CB 11/03/2016 - Fix issue with truncation error
CREATE PROC [dbo].[tdc_pps_pack_sp]  @is_cube_active  char(1),  
								@carton_no  int,  
								@carton_code  varchar(10),  
								@pack_type  varchar(10),  
								@user_id   varchar(50),  
								@station_id  varchar(3),  
								@tote_bin  varchar(12),  
								@order_no   int,  
								@order_ext   int,  
								@serial_no_raw  varchar(40),  
								@version  varchar(40),  
								@line_no   int,   
								@part_no   varchar(30),    
								@kit_item  varchar(30),  
								@location   varchar(10),   
								@lot_ser   varchar(25),   
								@bin_no_passed_in varchar(12),    
								@qty_to_pack  decimal (20,8),   
								@err_msg   varchar(255) OUTPUT  
  
AS  
BEGIN
  
	DECLARE @part varchar(30),  
			@mask_code varchar(15),  
			@no_of_sn int,  
			@ret int,  
			@vendor_sn char(1),  
			@warranty_track int,  
			@lb_tracking char(1),  
			@serial_no varchar(40),  
			@child_serial_no int,  
			@qty_avail decimal(20, 8),  
			@qty_to_process decimal(20, 8),  
			@tdc_generated int,  
			@previous_units_packed int,  
			@new_units_packed int,  
			@kit_part_no varchar(30),   
			@sub_kit_part_no varchar(30),  
			@bin_no varchar(12),  
			@qty decimal(20, 8),  
			@group_id varchar(12),
			@carrier varchar(10), -- v1.0  
			@global_lab varchar(10) -- v1.0

	-- v1.3 Start
	DECLARE	@row_id			int,
			@last_row_id	int
	-- v1.3 end
  
	SELECT	@group_id = group_id 
	FROM	tdc_pack_station_tbl(NOLOCK)  
	WHERE	station_id = @station_id  
  
	TRUNCATE TABLE #serial_no  
   
	--------------------------------------------------------------------------------------------------------------------  
	-- If the carton header does not exist, create it.  
	--------------------------------------------------------------------------------------------------------------------   
	IF NOT EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK) WHERE carton_no  = @carton_no  
				AND order_no = @order_no AND order_ext = @order_ext)   
	BEGIN     
		-- v1.2 Start
		IF EXISTS (SELECT 1 FROM cvo_order_third_party_ship_to (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND ISNULL(third_party_code,'') <> '')
		BEGIN
			INSERT INTO tdc_carton_tx (order_no, order_ext, carton_no, carton_type, carton_class, cust_code, cust_po,   
				carrier_code, shipper, ship_to_no, [name], address1, address2, address3, city, state, zip,   
				country, attention, date_shipped, weight, weight_uom, cs_tx_no, cs_tracking_no, cs_zone,   
				cs_oversize, cs_call_tag_no, cs_airbill_no, cs_other, cs_pickup_no, cs_dim_weight,   
				cs_published_freight, cs_disc_freight, cs_estimated_freight, cust_freight, freight_to,   
				adjust_rate, template_code, operator, consolidated_pick_no, void, status, station_id,   
				charge_code, bill_to_key, last_modified_date, modified_by, order_type, stlbin_no, stl_status)        
			SELECT @order_no, @order_ext, @carton_no, @carton_code, @pack_type, o.cust_code, o.cust_po, o.routing, '',    
				o.ship_to, o.ship_to_name, b.tp_address_1, b.tp_address_2,    
				b.tp_address_3, b.tp_city, b.tp_state,    
				LEFT(b.tp_zip,10), b.tp_country, o.attention, o.date_shipped, 0, 'LB',   -- v1.4
				'', '', NULL, '', '', NULL, NULL, '', NULL, NULL, NULL, NULL,    
				NULL, o.freight_to, NULL , NULL, @user_id, 0 , '0',    
				'O', @station_id, o.freight_allow_type, o.bill_to_key, getdate(), @user_id,    
				'S', '', 'N'   
			FROM	orders_all o (NOLOCK)
			JOIN	cvo_order_third_party_ship_to b (NOLOCK)
			ON		o.order_no = b.order_no
			AND		o.ext = b.order_ext  
			WHERE	o.order_no =  @order_no  
			AND		o.ext = @order_ext          

		END
		ELSE
		BEGIN
			INSERT INTO tdc_carton_tx (order_no, order_ext, carton_no, carton_type, carton_class, cust_code, cust_po,   
				carrier_code, shipper, ship_to_no, [name], address1, address2, address3, city, state, zip,   
				country, attention, date_shipped, weight, weight_uom, cs_tx_no, cs_tracking_no, cs_zone,   
				cs_oversize, cs_call_tag_no, cs_airbill_no, cs_other, cs_pickup_no, cs_dim_weight,   
				cs_published_freight, cs_disc_freight, cs_estimated_freight, cust_freight, freight_to,   
				adjust_rate, template_code, operator, consolidated_pick_no, void, status, station_id,   
				charge_code, bill_to_key, last_modified_date, modified_by, order_type, stlbin_no, stl_status)        
			SELECT @order_no, @order_ext, @carton_no, @carton_code, @pack_type, o.cust_code, o.cust_po, o.routing, '',    
				o.ship_to, o.ship_to_name, o.ship_to_add_1, o.ship_to_add_2,    
				o.ship_to_add_3, o.ship_to_city, o.ship_to_state,    
				LEFT(o.ship_to_zip,10), o.ship_to_country, o.attention, o.date_shipped, 0, 'LB',  -- v1.4
				'', '', NULL, '', '', NULL, NULL, '', NULL, NULL, NULL, NULL,    
				NULL, o.freight_to, NULL , NULL, @user_id, 0 , '0',    
				'O', @station_id, o.freight_allow_type, o.bill_to_key, getdate(), @user_id,    
				'S', '', 'N'   
			FROM	orders_all o (NOLOCK)   
			WHERE	o.order_no =  @order_no  
			AND		o.ext = @order_ext          
		END
		-- v1.2 End
    
		IF @@ERROR <> 0  
		BEGIN  
			SELECT @err_msg = 'Insert into tdc_carton_tx failed.'  
			RETURN -1  
		END  
   
	END --Carton header exists  
 
	-- START v1.1	
	/*
	-- v1.0
	IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND ISNULL(sold_to,'') <> '')
	BEGIN
		SELECT	@global_lab = ISNULL(sold_to,'')
		FROM	orders_all (NOLOCK) 
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		IF EXISTS (SELECT 1 FROM armaster_all (NOLOCK) WHERE customer_code = @global_lab AND address_type = 9
					AND (ISNULL(ship_via_code,'') = ''))
		BEGIN
			SELECT @err_msg = 'No Default Ship Via Set for this Global Ship To.'   
			RETURN -9  
		END

		SELECT	@carrier = ISNULL(ship_via_code,'')
		FROM	armaster_all (NOLOCK)
		WHERE	customer_code = @global_lab
		AND		address_type = 9

		IF @carrier > ''
		BEGIN
			UPDATE	tdc_carton_tx
			SET		carrier_code = @carrier
			WHERE	carton_no = @carton_no
		END

	END
	*/
	-- END v1.1

	--------------------------------------------------------------------------------------------------------------------  
	-- Make sure carton code and pack type match for all order/carton records.  
	--------------------------------------------------------------------------------------------------------------------  
	UPDATE	tdc_carton_tx  
	SET		carton_type = @carton_code,  
			carton_class = @pack_type  
	WHERE	carton_no = @carton_no  
  
	--------------------------------------------------------------------------------------------------------------------  
	-- If packing kit component, use the kit item  
	--------------------------------------------------------------------------------------------------------------------  
	IF @kit_item = ''   
		SELECT @part = @part_no  
	ELSE  
		SELECT @part = @kit_item  
  
	SELECT	@tdc_generated = tdc_generated   
	FROM	tdc_inv_master(NOLOCK)  
	WHERE	part_no = @part  
  
	--------------------------------------------------------------------------------------------------------------------  
	-- Get vendor_sn and warranty track  
	--------------------------------------------------------------------------------------------------------------------  
	SELECT @warranty_track = 0  
	SELECT	@vendor_sn = vendor_sn,  
			@warranty_track = ISNULL(warranty_track, 0)  
	FROM	tdc_inv_list (NOLOCK)  
	WHERE	location = @location  
    AND		part_no  = @part  
  
	--------------------------------------------------------------------------------------------------------------------  
	-- Determine if lb tracked  
	--------------------------------------------------------------------------------------------------------------------  
	SELECT	@lb_tracking = lb_tracking  
	-- v1.3 FROM	inventory (NOLOCK)  
	FROM	inv_master (NOLOCK)  
	WHERE	part_no = @part  
  
	IF @lb_tracking = 'N'  
	BEGIN  
		SELECT @lot_ser = NULL, @bin_no = NULL  
	END  
  
	--------------------------------------------------------------------------------------------------------------------  
	-- If outbound, tdc_generated serial numbers, generate the serial numbers  
	--------------------------------------------------------------------------------------------------------------------  
	IF @vendor_sn = 'O' AND EXISTS(SELECT * FROM tdc_inv_master (NOLOCK) WHERE part_no = @part AND tdc_generated = 1)  
	BEGIN  
		SELECT @mask_code = mask_code FROM tdc_inv_master (nolock) WHERE part_no = @Part     
   
		TRUNCATE TABLE #serial_no  
  
		SELECT @No_of_SN = CAST(FLOOR(@qty_to_pack) AS INT)  
  
		EXEC @ret = tdc_get_next_sn_sp @Part, @No_of_SN, @location  
  
		IF @ret < 0  
		BEGIN  
			SELECT @err_msg = 'Generate serial number failed!'  
			RETURN -2  
		END  
	END  
 
	--------------------------------------------------------------------------------------------------------------------  
	-- If the part is serialized and a masked serial is required, mask the serial number.  
	--------------------------------------------------------------------------------------------------------------------  
	ELSE IF @vendor_sn != 'N' AND ISNULL(@serial_no, '') = ''  
	BEGIN  
		EXEC @ret = tdc_format_serial_mask_sp @part, @serial_no_raw, @serial_no OUTPUT, @err_msg OUTPUT  
    
		If @ret < 0  
		BEGIN  
			SELECT @err_msg = 'Unable to format serial number mask'  
			RETURN -3  
		END  
	END  
  
	SELECT @qty_to_process = @qty_to_pack  
  
	--------------------------------------------------------------------------------------------------------------------  
	-- If item is not part of a custom kit  
	--------------------------------------------------------------------------------------------------------------------  
	IF ISNULL(@kit_item, '') = ''  
	BEGIN  

		-- v1.3 Start
		CREATE TABLE #item_pack_cur (
			row_id			int IDENTITY(1,1),
			child_serial_no	int NULL,
			bin_no			varchar(12) NULL,
			quantity		decimal(20,8))

		INSERT	#item_pack_cur (child_serial_no, bin_no, quantity)
		-- v1.3 DECLARE item_pack_cur CURSOR FOR  
		SELECT	child_serial_no, bin_no, quantity  
		FROM	tdc_dist_item_pick (NOLOCK)  
		WHERE	order_no      = @order_no  
		AND		order_ext     = @order_ext  
		AND		line_no       = @line_no  
		AND		part_no       = @part  
		AND		ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')  
		AND		[function]    = 'S'  
		AND		quantity     > 0  
		ORDER BY CASE WHEN bin_no = @bin_no_passed_in THEN 'A' + bin_no ELSE 'Z' + bin_no END  
  
		-- v1.3 OPEN item_pack_cur  
		-- v1.3 FETCH NEXT FROM item_pack_cur INTO @child_serial_no, @bin_no, @qty_avail  
  
		-- v1.3 WHILE @@FETCH_STATUS = 0 AND @qty_to_process > 0  

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@child_serial_no = child_serial_no,
				@bin_no = bin_no,
				@qty_avail = quantity
		FROM	#item_pack_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
		
		WHILE @@ROWCOUNT <> 0 AND @qty_to_process > 0  
		BEGIN  
  
			--------------------------------------------------------------------------------------------------------------------  
			-- Make sure not overpacking.  
			--------------------------------------------------------------------------------------------------------------------  
			IF @qty_avail > @qty_to_process 
				SELECT @qty_avail = @qty_to_process  
   
			/*--------------------------------------------------------------------------------------------------------------------  
			-- If serial tracked item, pack one at a time, and mask the masked serial number  
			--------------------------------------------------------------------------------------------------------------------  
			IF @vendor_sn != 'N'  
			BEGIN  
				SELECT @qty_avail = 1  
      
				EXEC @ret = tdc_format_serial_mask_sp @part, @serial_no_raw, @serial_no OUTPUT, @err_msg OUTPUT  
			END*/    
   
			IF @tdc_generated = 1 AND @vendor_sn = 'O'  
			BEGIN  
				SELECT @qty = 0  
				WHILE @qty < @qty_avail  
				BEGIN  
   
					--------------------------------------------------------------------------------------------------------------------  
					-- If tdc_generated, get the next generated serial number.  
					--------------------------------------------------------------------------------------------------------------------  
					IF @tdc_generated = 1  
					BEGIN  
						-- Get the next serial number  
						SELECT @serial_no = NULL  
						SELECT	TOP 1 @serial_no = serial_no  
						FROM	#serial_no   
       
						-- If unable to get the next number, exit  
						IF @serial_no IS NULL  
						BEGIN  
							SELECT @err_msg = 'Unable to get next serial number'  
							RETURN -4  
						END  
      
						-- Remove the serial number used from the temp table.		
						DELETE FROM #serial_no  
						WHERE	serial_no = @serial_no  
					END  
   
					INSERT tdc_serial_no_track (location,  transfer_location, part_no, lot_ser,  mask_code, serial_no, serial_no_raw, IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, last_trans, last_tx_control_no, date_time, [User_id], ARBC_No)  
					SELECT @location, @location, @Part, @lot_ser, @mask_code, @serial_no, @serial_no, 2, 'S', 'SPACK', @order_no, 'S', 'SPACK', @order_no, getdate(), @user_id, NULL  
     
					--------------------------------------------------------------------------------------------------------------------  
					-- Insert / Update the carton detail record.  
					--------------------------------------------------------------------------------------------------------------------  
					EXEC @ret = tdc_ins_upd_carton_det_rec @order_no, @order_ext, @carton_no, @line_no, @part, 1,   
							@lot_ser, @serial_no, @vendor_sn, @version, @warranty_track, NULL,   
							@err_msg OUTPUT, @user_id, @location, @serial_no_raw   
  
					SELECT @qty = @qty + 1   
				END  
			END   
			ELSE  
			BEGIN  
				--------------------------------------------------------------------------------------------------------------------  
				-- Insert / Update the carton detail record.  
				--------------------------------------------------------------------------------------------------------------------  
				EXEC @ret = tdc_ins_upd_carton_det_rec @order_no, @order_ext, @carton_no, @line_no, @part, @qty_avail,   
					@lot_ser, @serial_no, @vendor_sn, @version, @warranty_track, NULL,   
					@err_msg OUTPUT, @user_id, @location, @serial_no_raw   
			END  
  
			--------------------------------------------------------------------------------------------------------------------  
			-- Update tdc_dist_item_pick  
			--------------------------------------------------------------------------------------------------------------------  
   
			UPDATE	tdc_dist_item_pick   
			SET		quantity   = quantity - @qty_avail  
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		line_no    = @line_no   
			AND		ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')  
			AND		ISNULL(bin_no, '') = ISNULL(@bin_no, '')   
			AND		[function] = 'S'  
  
			IF @@ERROR != 0  
			BEGIN  
				SELECT @err_msg = 'UPDATE tdc_dist_item_pick failed.'  
				RETURN -6  
			END        
    
			--------------------------------------------------------------------------------------------------------------------  
			-- Update tdc_dist_group  
			--------------------------------------------------------------------------------------------------------------------  
			IF EXISTS(SELECT * FROM tdc_dist_group (NOLOCK) WHERE parent_serial_no = @carton_no  
					AND child_serial_no  = @child_serial_no AND [function]       = 'S')  
			BEGIN  
				UPDATE	tdc_dist_group   
				SET		quantity = quantity + @qty_avail  
				WHERE	parent_serial_no = @carton_no   
				AND		child_serial_no  = @child_serial_no  
				AND		[function]  = 'S'   
   
				IF @@ERROR != 0  
				BEGIN  
					SELECT @err_msg = 'UPDATE tdc_dist_group failed.'  
					RETURN -7  
				END  
			END  
			ELSE  
			BEGIN   
				INSERT tdc_dist_group (method, type, parent_serial_no, child_serial_no, quantity, status, [function])  
				VALUES ('01', 'N1', @carton_no, @child_serial_no, @qty_avail, 'O', 'S')  
   
				IF @@ERROR != 0  
				BEGIN  
					SELECT @err_msg = 'INSERT tdc_dist_group failed.'  
					RETURN -8  
				END  
			END  
     
			--------------------------------------------------------------------------------------------------------------------  
			-- Update tdc_tote_bin_tbl  
			--------------------------------------------------------------------------------------------------------------------       
			IF @tote_bin <> ''  
			BEGIN  
				UPDATE	tdc_tote_bin_tbl 
				SET		quantity = quantity - @qty_avail  
				WHERE	bin_no    = @tote_bin  
				AND		order_no  = @order_no  
				AND		order_ext = @order_ext  
				AND		location  = @location  
				AND		line_no   = @line_no  
				AND		part_no   = @part  
				AND		ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')  
				AND		ISNULL(orig_bin, '') = ISNULL(@bin_no, '')  
   
				IF @@ERROR != 0  
				BEGIN  
					SELECT @err_msg = 'UPDATE tdc_tote_bin_tbl failed'  
					RETURN -9  
				END  
    
				DELETE	FROM tdc_tote_bin_tbl 
				WHERE	quantity = 0  
				AND		bin_no    = @tote_bin  
				AND		order_no  = @order_no  
				AND		order_ext = @order_ext  
				AND		location  = @location  
				AND		line_no   = @line_no  
				AND		part_no   = @part  
				AND		ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')  
				AND		ISNULL(orig_bin, '') = ISNULL(@bin_no, '')  
   
				IF @@ERROR != 0  
				BEGIN  
					SELECT @err_msg = 'DELETE FROM tdc_tote_bin_tbl failed'  
					RETURN -10  
				END  
			END     
  
			--------------------------------------------------------------------------------------------------------------------  
			-- Log the transaction  
			--------------------------------------------------------------------------------------------------------------------  
			INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
			VALUES (GETDATE(),@user_id, 'VB', 'PPS', 'Pack Carton', @order_no, @order_ext, @part_no, @lot_ser, @bin_no, @location, @qty_to_pack, NULL)  
    
			--------------------------------------------------------------------------------------------------------------------  
			-- Insert for the cube  
			--------------------------------------------------------------------------------------------------------------------  
			-- IF @is_cube_active = 'Y'  
			-- BEGIN   
				--  INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning, carton_no, tran_no, tran_ext, location, part_no, bin_no, quantity)  
				--  VALUES (@station_id, @user_id, 'VB', 'PPS', 'Pack Carton', 0, @carton_no, @order_no, @order_ext, @location, @part_no, @bin_no, @qty_to_pack)  
			-- END  
  
			--------------------------------------------------------------------------------------------------------------------  
			-- Decrement the pack counter  
			--------------------------------------------------------------------------------------------------------------------  
			SELECT @qty_to_process = @qty_to_process - @qty_avail  
  
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@child_serial_no = child_serial_no,
					@bin_no = bin_no,
					@qty_avail = quantity
			FROM	#item_pack_cur
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
  
			-- v1.3 FETCH NEXT FROM item_pack_cur INTO @child_serial_no, @bin_no, @qty_avail  
  
		END   
	
		-- v1.3 CLOSE item_pack_cur  
		-- v1.3 DEALLOCATE item_pack_cur  
  
	END  
	ELSE  
		--------------------------------------------------------------------------------------------------------------------  
		-- Custom kit items  
		--------------------------------------------------------------------------------------------------------------------  
	BEGIN  
		--------------------------------------------------------------------------------------------------------------------  
		-- Get the kit_part_no and sub_kit_part_no  
		--------------------------------------------------------------------------------------------------------------------  
		SELECT @sub_kit_part_no = NULL  
  
		SELECT	@sub_kit_part_no = sub_kit_part_no,   
				@kit_part_no = kit_part_no  
		FROM	tdc_ord_list_kit(NOLOCK)  
		WHERE	order_no = @order_no  
		AND		order_ext = @order_ext  
		AND		line_no = @line_no  
		AND		sub_kit_part_no = @kit_item  
  
		IF @sub_kit_part_no IS NULL  
		BEGIN  
			SELECT @kit_part_no = @kit_item  
		END   
  
		--------------------------------------------------------------------------------------------------------------------  
		-- Get the previous number of custom kits packed  
		--------------------------------------------------------------------------------------------------------------------  
		EXEC @previous_units_packed = tdc_cust_kit_units_packed_sp @order_no, @order_ext, 0, @line_no  
  
		-- v1.3 Start
		CREATE TABLE #item_pack_cur_kit (
			row_id		int IDENTITY(1,1),
			bin_no		varchar(12) NULL,
			quantity	decimal(20,8))
  
		INSERT	#item_pack_cur_kit (bin_no, quantity)
		-- v1.3 DECLARE item_pack_cur CURSOR FOR  
		SELECT	a.bin_no, a.qty - ISNULL((SELECT SUM(qty)   
								FROM	tdc_custom_kits_packed_tbl b(NOLOCK)  
								WHERE	b.order_no   = a.tran_no   
								AND		b.order_ext  = a.tran_ext  
								AND		b.line_no    = a.line_no  
								AND		(b.kit_part_no = a.part_no OR b.sub_kit_part_no = a.part_no)  
								AND		b.lot_ser    = a.lot_ser  
								AND b.bin_no     = a.bin_no),0)   
		FROM	lot_bin_ship a(NOLOCK)  
		WHERE	a.tran_no  = @order_no  
		AND		a.tran_ext = @order_ext  
		AND		a.line_no  = @line_no  
		AND		a.part_no  = @kit_item  
		AND		a.lot_ser  = @lot_ser  
		UNION  
        SELECT	NULL, SUM(kit_picked) - ISNULL((SELECT SUM(pack_qty)   
											FROM	tdc_carton_detail_tx b(NOLOCK)  
											WHERE	b.order_no   = a.order_no   
											AND		b.order_ext  = a.order_ext  
											AND		b.line_no    = a.line_no  
											AND		part_no = @kit_item),0)   
		FROM	tdc_ord_list_kit a, inv_master b(NOLOCK)  
		WHERE	a.order_no   = @order_no  
		AND		a.order_ext  = @order_ext  
		AND		a.line_no    = @line_no  
		AND		b.part_no    = @kit_item  
		AND		b.lb_tracking = 'N'  
		AND		(a.kit_part_no = @kit_item OR a.sub_kit_part_no = @kit_item)  
		GROUP BY a.order_no, a.order_ext, a.line_no, a.kit_part_no, a.sub_kit_part_no  
    
		-- v1.3 OPEN item_pack_cur  
		-- v1.3 FETCH NEXT FROM item_pack_cur INTO @bin_no, @qty_avail  
		-- v1.3 WHILE @@FETCH_STATUS = 0 AND @qty_to_process > 0  

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@bin_no = bin_no,
				@qty_avail = quantity
		FROM	#item_pack_cur_kit
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0 AND @qty_to_process > 0)
		BEGIN  
  
			--------------------------------------------------------------------------------------------------------------------  
			-- Make sure not overpacking.  
			--------------------------------------------------------------------------------------------------------------------  
			IF @qty_avail > @qty_to_process SELECT @qty_avail = @qty_to_process  
  
			IF @qty_avail > 0  
			BEGIN  
				--------------------------------------------------------------------------------------------------------------------  
				-- If serial tracked item, pack one at a time, and mask the masked serial number  
				--------------------------------------------------------------------------------------------------------------------  
				IF @vendor_sn != 'N'  
				BEGIN  
					SELECT @qty_avail = 1  
		
					EXEC @ret = tdc_format_serial_mask_sp @part, @serial_no_raw, @serial_no OUTPUT, @err_msg OUTPUT  
				END    
   
				SELECT @qty = 0  
				WHILE @qty < @qty_avail  
				BEGIN  
					IF @tdc_generated = 1 AND @vendor_sn = 'O'  
					BEGIN  
						--------------------------------------------------------------------------------------------------------------------  
						-- If tdc_generated, get the next generated serial number.  
						--------------------------------------------------------------------------------------------------------------------  
						IF @tdc_generated = 1  
						BEGIN  
							-- Get the next serial number  
							SELECT @serial_no = NULL  
							SELECT	TOP 1 @serial_no = serial_no  
							FROM	#serial_no   
       
							-- If unable to get the next number, exit  
							IF @serial_no IS NULL  
							BEGIN  
								SELECT @err_msg = 'Unable to get next serial number'  
								RETURN -4  
							END  
      
							-- Remove the serial number used from the temp table.  
							DELETE FROM #serial_no  
							WHERE serial_no = @serial_no  
						END  
   
						INSERT tdc_serial_no_track (location,  transfer_location, part_no, lot_ser,  mask_code, serial_no, serial_no_raw, IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, last_trans, last_tx_control_no, date_time, [User_id], ARBC_No)  
						SELECT @location, @location, @Part, @lot_ser, @mask_code, @serial_no, @serial_no, 2, 'S', 'SPACK', @order_no, 'S', 'SPACK', @order_no, getdate(), @user_id, NULL  
     
						SELECT @qty = @qty + 1  
					END   
					ELSE  
					BEGIN  
						SELECT @qty = @qty + @qty_avail  
					END  
   
					--------------------------------------------------------------------------------------------------------------------  
					-- Insert / Update the carton detail record.  
					--------------------------------------------------------------------------------------------------------------------  
					EXEC @ret = tdc_ins_upd_carton_det_rec @order_no, @order_ext, @carton_no, @line_no, @part, @qty,   
						@lot_ser, @serial_no, @vendor_sn, @version, @warranty_track, NULL,   
						@err_msg OUTPUT, @user_id, @location, @serial_no_raw   
   
       
				END  
   
				--------------------------------------------------------------------------------------------------------------------  
				-- Update the tdc_cust_kits_packed table  
				--------------------------------------------------------------------------------------------------------------------  
				IF @lb_tracking = 'Y'  
				BEGIN     
					IF EXISTS(SELECT * FROM tdc_custom_kits_packed_tbl (NOLOCK) WHERE carton_no = @carton_no  
						AND order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND kit_part_no = @kit_part_no  
						AND ISNULL(sub_kit_part_no, '') = ISNULL(@sub_kit_part_no, '') AND lot_ser = @lot_ser AND bin_no = @bin_no)  
					BEGIN  
						UPDATE	tdc_custom_kits_packed_tbl  
						SET		qty = qty + @qty_avail  
						WHERE	carton_no = @carton_no  
						AND		order_no = @order_no  
						AND		order_ext = @order_ext  
						AND		line_no = @line_no  
						AND		kit_part_no = @kit_part_no  
						AND		ISNULL(sub_kit_part_no, '') = ISNULL(@sub_kit_part_no, '')  
						AND		lot_ser = @lot_ser   
						AND		bin_no = bin_no   
     
					END  
					ELSE  
					BEGIN  
						INSERT INTO tdc_custom_kits_packed_tbl(carton_no, order_no, order_ext, line_no, kit_part_no, sub_kit_part_no, lot_ser, bin_no, qty)  
						VALUES(@carton_no, @order_no, @order_ext, @line_no, @kit_part_no, @sub_kit_part_no, @lot_ser, @bin_no, @qty_avail)  
					END  
				END   
  
				SELECT @qty_to_process = @qty_to_process - @qty_avail  
			END -- @qty_avail > 0  
  
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@bin_no = bin_no,
					@qty_avail = quantity
			FROM	#item_pack_cur_kit
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
			
			-- v1.3 FETCH NEXT FROM item_pack_cur INTO @bin_no, @qty_avail  
		END   
	
		-- v1.3CLOSE item_pack_cur  
		-- v1.3 DEALLOCATE item_pack_cur  
  
		IF @qty_to_process > 0   
		BEGIN  
			SELECT @err_msg = 'Unable to pack entire quantity.'  
			RETURN -6  
		END  
  
		--------------------------------------------------------------------------------------------------------------------  
		-- Get the new number of units packed  
		--------------------------------------------------------------------------------------------------------------------  
		EXEC @new_units_packed = tdc_cust_kit_units_packed_sp @order_no, @order_ext, 0, @line_no  
		SELECT @new_units_packed = @new_units_packed - @previous_units_packed   
  
		--------------------------------------------------------------------------------------------------------------------  
		-- Update tdc_dist_item_pick  
		--------------------------------------------------------------------------------------------------------------------  
		IF @new_units_packed > 0   
		BEGIN  
			UPDATE	tdc_dist_item_pick   
			SET		quantity   = quantity - @new_units_packed  
			WHERE	order_no   = @order_no  
			AND		order_ext  = @order_ext  
			AND		line_no    = @line_no    
			AND		[function] = 'S'  
   
			IF @@ERROR != 0  
			BEGIN  
				SELECT @err_msg = 'UPDATE tdc_dist_item_pick failed.'  
				RETURN -6  
			END  
    
			--------------------------------------------------------------------------------------------------------------------  
			-- Update tdc_dist_group  
			--------------------------------------------------------------------------------------------------------------------  
			SELECT	TOP 1 @child_serial_no = child_serial_no   
			FROM	tdc_dist_item_pick (NOLOCK)  
			WHERE	order_no      = @order_no  
			AND		order_ext     = @order_ext  
			AND		line_no       = @line_no  
			AND		part_no       = @part_no  
			AND		[function]    = 'S'  
   
   
			IF @child_serial_no IS NOT NULL  
			BEGIN  
				IF EXISTS(SELECT * FROM tdc_dist_group (NOLOCK) WHERE parent_serial_no = @carton_no AND child_serial_no  = @child_serial_no  
							AND [function]       = 'S')  
				BEGIN  
					UPDATE	tdc_dist_group   
					SET		quantity = quantity + @new_units_packed  
					WHERE	parent_serial_no = @carton_no   
					AND		child_serial_no  = @child_serial_no  
					AND		[function]  = 'S'   
    
					IF @@ERROR != 0  
					BEGIN  
						SELECT @err_msg = 'UPDATE tdc_dist_group failed.'  
						RETURN -7  
					END  
				END  
				ELSE  
				BEGIN   
					INSERT tdc_dist_group (method, type, parent_serial_no, child_serial_no, quantity, status, [function])  
					VALUES ('01', 'N1', @carton_no, @child_serial_no, @new_units_packed, 'O', 'S')  
    
					IF @@ERROR != 0  
					BEGIN  
						SELECT @err_msg = 'INSERT tdc_dist_group failed.'  
						RETURN -8  
					END  
				END  
			END  
		END  
   
	END  
  
  
   
	UPDATE	tdc_pack_queue   
    SET		packed = packed + @qty_to_pack,  
			last_modified_date = GETDATE(),  
			last_modified_by = @user_id  
	WHERE	group_id = @group_id  
    AND		order_no = @order_no  
    AND		order_ext = @order_ext  
    AND		line_no = @line_no  
    AND		part_no = @part    
  
	RETURN 0  
END
GO

GRANT EXECUTE ON  [dbo].[tdc_pps_pack_sp] TO [public]
GO
