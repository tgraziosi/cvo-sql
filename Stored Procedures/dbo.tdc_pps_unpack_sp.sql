SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_pps_unpack_sp]
	@is_cube_active		char(1),
	@carton_no		int,
	@user_id 		varchar(50),
	@station_id		varchar(3),
	@tote_bin		varchar(12),
	@order_no 		int,
	@order_ext 		int,
	@serial_no 		varchar(40),
	@version		varchar(40),
	@line_no 		int, 
	@part_no 		varchar(30),  
	@kit_item		varchar(30),
	@location 		varchar(10), 
	@lot_ser 		varchar(25), 
	@bin_no_passed_in	varchar(12), 	
	@qty_to_unpack		decimal (20,8), 
	@err_msg 		varchar(255) OUTPUT

AS

DECLARE @qty_avail	  decimal(24,8),
	@qty_to_process	  decimal(24,8),
	@qty_processed	  decimal(24,8),
	@parent_serial_no int, 
	@child_serial_no  int,
	@part	  	  varchar(30),
	@vendor_sn	  char(1),
	@warranty_track	  int,
	@tran_num	  int,
	@ret		  int,
	@carton_qty	  decimal(24,8),
	@lb_tracking	  char(1),
	@kits_packed	  decimal(24,8),
	@kits_unpacked    decimal(24,8),
	@bin_no		  varchar(12),
	@sub_kit_part_no  varchar(30),
	@kit_part_no 	  varchar(30),
	@pack_group	  varchar(12)


	SELECT @qty_to_process = 0
	SELECT @qty_processed = 0

	SELECT @pack_group = group_id
	  FROM tdc_pack_station_tbl (NOLOCK)
	 WHERE station_id = @station_id

	--------------------------------------------------------------------------------------------------------------------
	-- If packing kit component, use the kit item
	--------------------------------------------------------------------------------------------------------------------
	IF @kit_item = '' 
		SELECT @part = @part_no
	ELSE
		SELECT @part = @kit_item

	--------------------------------------------------------------------------------------------------------------------
	-- Get vendor_sn and warranty track
	--------------------------------------------------------------------------------------------------------------------
	SELECT @warranty_track = 0
	SELECT @vendor_sn = vendor_sn,
	       @warranty_track = ISNULL(warranty_track, 0)
	  FROM tdc_inv_list (NOLOCK)
	 WHERE location = @location
	   AND part_no  = @part	
 
	--------------------------------------------------------------------------------------------------------------------
	-- Determine if lb tracked
	--------------------------------------------------------------------------------------------------------------------
	SELECT @lb_tracking = lb_tracking
	  FROM inventory (NOLOCK)
	 WHERE part_no = @part


	-------------------------------------------------------------------------------------------------------------------- 
	-- Not a custom kit
	--------------------------------------------------------------------------------------------------------------------
	IF ISNULL(@kit_item, '') = ''
	BEGIN	
			
		--------------------------------------------------------------------------------------------------------------------
		-- Insert / Update the carton detail record.
		--------------------------------------------------------------------------------------------------------------------
		SELECT @qty_to_process = @qty_to_unpack
		SELECT @carton_qty = 0 - @qty_to_unpack

		EXEC @ret = tdc_ins_upd_carton_det_rec  @order_no, @order_ext, @carton_no, @line_no, @part_no, 	
							@carton_qty, @lot_ser, '', @vendor_sn, @version, 
							@warranty_track, @tran_num, @err_msg OUTPUT,
					    		@user_id, @location, @serial_no 	
		IF (@ret < 0) RETURN -1


		DECLARE un_pack_cur
		 CURSOR FOR 	
			SELECT a.bin_no, b.quantity, b.parent_serial_no, b.child_serial_no
			  FROM tdc_dist_item_pick a(NOLOCK),
			       tdc_dist_group     b(NOLOCK)
			 WHERE a.order_no   	  	= @order_no
			   AND a.order_ext 	  	= @order_ext
			   AND a.line_no   	  	= @line_no
			   AND ISNULL(a.lot_ser, '')	= ISNULL(@lot_ser, '')
			   AND part_no     	  	= @part
			   AND a.child_serial_no  	= b.child_serial_no
			   AND b.parent_serial_no 	= @carton_no
			 ORDER BY CASE WHEN ISNULL(a.bin_no, '') 	= ISNULL(@bin_no_passed_in, '')
						THEN 'A' + ISNULL(a.bin_no, '')
						ELSE 'B' + ISNULL(a.bin_no, '')
					END
		OPEN un_pack_cur
		FETCH NEXT FROM un_pack_cur INTO @bin_no, @qty_avail, @parent_serial_no, @child_serial_no
				
		
		WHILE @@FETCH_STATUS = 0 AND @qty_to_process > 0
		BEGIN

			IF (@qty_to_process <= @qty_avail)
			BEGIN
				UPDATE tdc_dist_group 
				   SET quantity = quantity - @qty_to_process
				 WHERE parent_serial_no = @parent_serial_no 
				   AND child_serial_no  = @child_serial_no
				   AND [function] 	= 'S' 
		
				UPDATE tdc_dist_item_pick
				   SET quantity = quantity + @qty_to_process
				 WHERE child_serial_no  = @child_serial_no
				   AND [function] 	= 'S'  
		
				DELETE FROM tdc_dist_group
				 WHERE parent_serial_no = @parent_serial_no 
				   AND child_serial_no  = @child_serial_no 
				   AND quantity 	= 0 
				   AND [function] 	= 'S'
		
				SELECT @qty_processed = ISNULL(@qty_to_process,0)
				SELECT @qty_to_process = 0
			END
			ELSE
			BEGIN
				DELETE FROM tdc_dist_group
				 WHERE parent_serial_no = @parent_serial_no 
				   AND child_serial_no  = @child_serial_no
				   AND [function] 	= 'S' 
		
				UPDATE tdc_dist_item_pick
				   SET quantity = quantity + @qty_avail
				 WHERE child_serial_no  = @child_serial_no
				   AND [function] 	= 'S' 
				
				SELECT @qty_processed  = ISNULL(@qty_avail,0)
				SELECT @qty_to_process = @qty_to_process - @qty_avail
			END	
			
			IF ISNULL(@tote_bin, '') != ''
			BEGIN
				IF EXISTS(SELECT * 
					    FROM tdc_tote_bin_tbl (NOLOCK)
					   WHERE bin_no    = @tote_bin
					     AND order_no  = @order_no
					     AND order_ext = @order_ext
					     AND location  = @location
					     AND line_no   = @line_no
					     AND part_no   = @part_no
					     AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
					     AND ISNULL(orig_bin, '') = ISNULL(@bin_no, ''))
				BEGIN
					UPDATE tdc_tote_bin_tbl SET quantity = quantity + @qty_processed
					 WHERE bin_no    = @tote_bin
				           AND order_no  = @order_no
				     	   AND order_ext = @order_ext
					   AND location  = @location
					   AND line_no   = @line_no
					   AND part_no   = @part_no
					   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
					   AND ISNULL(orig_bin, '') = ISNULL(@bin_no, '')
				END
				ELSE
				BEGIN
					IF NOT EXISTS(SELECT * from inv_master (nolock) where part_no = @part_no AND lb_tracking = 'Y')
					BEGIN
						--scr 36446 
						INSERT INTO tdc_tote_bin_tbl (bin_no, order_no, order_ext, location, line_no,
									      part_no, lot_ser, orig_bin, quantity, tran_date, who, order_type)
						VALUES (@tote_bin, @order_no, @order_ext, @location, @line_no, @part_no, NULL, 
							NULL, @qty_processed, GETDATE(), @user_id, 'S')
					END
					ELSE
					BEGIN
						INSERT INTO tdc_tote_bin_tbl (bin_no, order_no, order_ext, location, line_no,
									      part_no, lot_ser, orig_bin, quantity, tran_date, who, order_type)
						VALUES (@tote_bin, @order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, 
							@bin_no, @qty_processed, GETDATE(), @user_id, 'S')	
					END
				END
			END
	 
			FETCH NEXT FROM un_pack_cur INTO @bin_no, @qty_avail, @parent_serial_no, @child_serial_no
		
		END
		CLOSE un_pack_cur
		DEALLOCATE un_pack_cur
		
		-------------------------------------------------------------------------------------------------------------------
		-- Make sure unpack did not fail
		-------------------------------------------------------------------------------------------------------------------
		IF @qty_to_process > 0 
		BEGIN
			SELECT @err_msg = 'Qty not available to unpack'
			RETURN -1
		END
	END --NOT A KIT
	ELSE
	-------------------------------------------------------------------------------------------------------------------
	-- CUSTOM KITS
	-------------------------------------------------------------------------------------------------------------------
	BEGIN			
		-------------------------------------------------------------------------------------------------------------------
		-- Update carton detail record(s)
		-------------------------------------------------------------------------------------------------------------------
		SELECT @carton_qty = 0 - @qty_to_unpack
	
		EXEC @kits_packed = tdc_cust_kit_units_packed_sp @order_no, @order_ext, 0, @line_no
	
		EXEC @ret = tdc_ins_upd_carton_det_rec  @order_no, @order_ext, @carton_no, @line_no, @kit_item, 	
							@carton_qty, @lot_ser, '', @vendor_sn, @version, 
							@warranty_track, @tran_num, @err_msg OUTPUT,
					    		@user_id, @location, @serial_no 	
	    
		IF (@ret < 0) RETURN -1
				
		EXEC @kits_unpacked = tdc_cust_kit_units_packed_sp @order_no, @order_ext, 0, @line_no
		SELECT @kits_unpacked = @kits_packed - @kits_unpacked
	
	
		-------------------------------------------------------------------------------------------------------------------
		-- Update the dist_group table
		-------------------------------------------------------------------------------------------------------------------	
	
		IF @kits_unpacked > 0
		BEGIN
	
			UPDATE tdc_dist_item_pick 
			   SET quantity   = quantity + @kits_unpacked
			 WHERE order_no   = @order_no
			   AND order_ext  = @order_ext
			   AND line_no    = @line_no
			   AND [function] = 'S'
	
			SELECT @child_serial_no = child_serial_no 
			  FROM tdc_dist_item_pick (NOLOCK)
			 WHERE order_no   = @order_no
			   AND order_ext  = @order_ext
			   AND line_no    = @line_no
			   AND [function] = 'S'
	
			UPDATE tdc_dist_group
			   SET quantity = quantity - @kits_unpacked
			 WHERE parent_serial_no = @carton_no
			   AND child_serial_no  = @child_serial_no
				   AND [function] 	= 'S'
	
			DELETE FROM tdc_dist_group
			 WHERE parent_serial_no = @carton_no
			   AND child_serial_no  = @child_serial_no
			   AND [function] 	= 'S'
			   AND quantity		= 0
		END
	
		--------------------------------------------------------------------------------------------------------------------
		-- get the kit_part_no, sub_kit_part_no
		--------------------------------------------------------------------------------------------------------------------
		SELECT @sub_kit_part_no = NULL

		SELECT @sub_kit_part_no = sub_kit_part_no, 
		       @kit_part_no = kit_part_no
		  FROM tdc_ord_list_kit(NOLOCK)
		 WHERE order_no = @order_no
		   AND order_ext = @order_ext
		   AND line_no = @line_no
		   AND sub_kit_part_no = @kit_item

		IF @sub_kit_part_no IS NULL
		BEGIN
			SELECT @kit_part_no = @kit_item
		END 	

		-------------------------------------------------------------------------------------------------------------------
		-- LB/TRACKED PARTS
		-------------------------------------------------------------------------------------------------------------------
		IF @lb_tracking = 'Y'
		BEGIN
			SELECT @qty_to_process = @qty_to_unpack 
	
			DECLARE un_pick_kit_cur
			 CURSOR FOR 
				SELECT bin_no, qty 
				  FROM tdc_custom_kits_packed_tbl (NOLOCK)
				 WHERE carton_no    = @carton_no
				   AND line_no      = @line_no
				   AND (kit_part_no = @kit_item OR sub_kit_part_no = @kit_item)
				   AND lot_ser      = @lot_ser
				 ORDER BY CASE WHEN bin_no = @bin_no_passed_in 
							THEN 'A' + bin_no 
							ELSE 'B' + bin_no 
					       END
	 	   
			OPEN un_pick_kit_cur
			FETCH NEXT FROM un_pick_kit_cur INTO @bin_no, @qty_avail 
									
			WHILE @@FETCH_STATUS = 0 AND @qty_to_process > 0
			BEGIN
			
				IF @qty_avail <= @qty_to_process 	
				BEGIN
					SELECT @qty_processed  = @qty_avail
					SELECT @qty_to_process = @qty_to_process - @qty_avail
				END
				ELSE
				BEGIN
					SELECT @qty_processed = @qty_to_process
					SELECT @qty_to_process = 0
				
				END						

				--------------------------------------------------------------------------------------------------------------------
				-- Update/Delete tdc_custom_kits_packed_tbl
				--------------------------------------------------------------------------------------------------------------------
				UPDATE tdc_custom_kits_packed_tbl
				   SET qty = qty - @qty_processed
				 WHERE carton_no = @carton_no
				   AND order_no = @order_no
				   AND order_ext = @order_ext
				   AND line_no = @line_no
				   AND kit_part_no = @kit_part_no
				   AND ISNULL(sub_kit_part_no, '') = ISNULL(@sub_kit_part_no, '')
				   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
				   AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')
		
		
				DELETE FROM tdc_custom_kits_packed_tbl
				 WHERE carton_no = @carton_no
				   AND order_no = @order_no
				   AND order_ext = @order_ext
				   AND line_no = @line_no
				   AND kit_part_no = @kit_part_no
				   AND ISNULL(sub_kit_part_no, '') = ISNULL(@sub_kit_part_no, '')
				   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
				   AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')
				   AND qty = 0					
	 
				IF @tote_bin != ''
				BEGIN
					IF EXISTS(SELECT * 
						    FROM tdc_tote_bin_tbl (NOLOCK)
						   WHERE bin_no    = @tote_bin
						     AND order_no  = @order_no
						     AND order_ext = @order_ext
						     AND location  = @location
						     AND line_no   = @line_no
						     AND part_no   = @kit_item
						     AND lot_ser   = @lot_ser
						     AND orig_bin  = @bin_no)
					BEGIN
						UPDATE tdc_tote_bin_tbl SET quantity = quantity + @qty_processed
						 WHERE bin_no    = @tote_bin
					           AND order_no  = @order_no
					     	   AND order_ext = @order_ext
						   AND location  = @location
						   AND line_no   = @line_no
						   AND part_no   = @kit_item
						   AND lot_ser   = @lot_ser
						   AND orig_bin  = @bin_no
					END
					ELSE
					BEGIN
						INSERT INTO tdc_tote_bin_tbl (bin_no, order_no, order_ext, location, line_no,
									      part_no, lot_ser, orig_bin, quantity, tran_date, who, order_type)
						VALUES (@tote_bin, @order_no, @order_ext, @location, @line_no, @kit_item, @lot_ser, 
							@bin_no, @qty_processed, GETDATE(), @user_id, 'S')
					END
				END
				FETCH NEXT FROM un_pick_kit_cur INTO @bin_no, @qty_avail 
			
			END
			CLOSE un_pick_kit_cur
			DEALLOCATE un_pick_kit_cur
	 
			-------------------------------------------------------------------------------------------------------------------
			-- Make sure unpack did not fail
			-------------------------------------------------------------------------------------------------------------------
			IF @qty_to_process > 0 
			BEGIN
				SELECT @err_msg = 'Qty not available to unpack'
				RETURN -1
			END
		END --LB/TRACKED
		ELSE
		BEGIN
			IF @tote_bin != ''
			BEGIN
				IF EXISTS(SELECT * 
					    FROM tdc_tote_bin_tbl (NOLOCK)
					   WHERE bin_no    = @tote_bin
					     AND order_no  = @order_no
					     AND order_ext = @order_ext
					     AND location  = @location
					     AND line_no   = @line_no
					     AND part_no   = @kit_item
					     AND lot_ser   IS NULL
					     AND orig_bin  IS NULL)
				BEGIN
	
					UPDATE tdc_tote_bin_tbl SET quantity = quantity + @qty_to_unpack
					 WHERE bin_no    = @tote_bin
				           AND order_no  = @order_no
				     	   AND order_ext = @order_ext
					   AND location  = @location
					   AND line_no   = @line_no
					   AND part_no   = @kit_item
					   AND lot_ser   IS NULL
					   AND orig_bin  IS NULL
	
				END
				ELSE
				BEGIN
	
					INSERT INTO tdc_tote_bin_tbl (bin_no, order_no, order_ext, location, line_no,
								      part_no, lot_ser, orig_bin, quantity, tran_date, who, order_type)
					VALUES (@tote_bin, @order_no, @order_ext, @location, @line_no, @kit_item, NULL, 
						NULL, ISNULL(@qty_to_unpack,0), GETDATE(), @user_id, 'S')
	
				END	
			END
		END
	
	END --KIT ITEM

	IF @vendor_sn = 'O'
	BEGIN
 		DELETE FROM tdc_serial_no_track
		 WHERE location = @location
		   AND part_no = @part
		   AND lot_ser = @lot_ser
		   AND serial_no_raw = @serial_no
	END

	INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
	VALUES (GETDATE(),@user_id, 'VB', 'PPS', 'Unpack Carton', @order_no, @order_ext, @part_no, @lot_ser, @bin_no, @location, @qty_to_unpack, NULL)    	

--	IF @is_cube_active = 'Y'
--	BEGIN
		-- added on 8-13-01 by Trevor Emond for Analysis Services
--		INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning, carton_no, tran_no, tran_ext, location, part_no, bin_no, quantity)
--		VALUES (@station_id, @user_id, 'VB', 'PPS', 'Unpack Carton', 0, @carton_no, @order_no, @order_ext, @location, @part_no, @bin_no,  @qty_to_unpack)  
--	END


	UPDATE tdc_pack_queue 
	   SET packed = packed - @qty_to_unpack,
	       last_modified_date = GETDATE(),
	       last_modified_by = @user_id
	 WHERE group_id = @pack_group
	   AND order_no = @order_no
 	   AND order_ext = @order_ext
	   AND line_no = @line_no
	   AND part_no = @part		

	DELETE FROM tdc_pack_queue 
	 WHERE group_id = @pack_group
	   AND order_no = @order_no
 	   AND order_ext = @order_ext
	   AND line_no = @line_no
	   AND part_no = @part		
	   AND picked <= 0

	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_unpack_sp] TO [public]
GO
