SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_packverify_pack_sp] 
	@order_no 			int,
	@order_ext 			int,
	@carton_no 			int,
	@line_no 			int, 
	@part_no 			varchar(30), 
	@location 			varchar(10), 
	@lot_ser			varchar(25),
	@bin_no				varchar(12),
	@qty 				decimal(24,8), 
	@user_id 			varchar(50),
	@station_id			int,
	@carton_type    		varchar(10),
	@carton_class   		varchar(10),
	@not_using_orig_allocation 	char(1),
	@error_msg 			varchar(255) 	OUTPUT
AS

DECLARE @serial_flag 	  varchar(10),
	@warranty_track	  bit,
	@receipt_no	  varchar(30),
	@sp_return	  int,
	@formatted_serial varchar(40),
	@serial_no        varchar(40),
	@version_no 	  varchar(40),
	@language 	  varchar(10)

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')
	SELECT @warranty_track = 0

	-- a) Refresh the carton header record in case the Order information has changed
	EXEC tdc_refresh_carton_sp @carton_no

	IF @@ERROR <> 0
	BEGIN
                -- 'Unable to pack: tdc_refresh_carton_sp SP failed.'
		SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -101 AND language = @language 
                RETURN -1
	END
	
	-- b) Check if part is TDC serialized and some serial numbers have been scanned
	IF EXISTS(SELECT * FROM #scanned_serials)
	BEGIN
		DECLARE serials_cursor CURSOR FOR 
			SELECT DISTINCT serial_no, version_no, lot_ser, bin_no FROM #scanned_serials
		
		OPEN serials_cursor
		FETCH NEXT FROM serials_cursor INTO @serial_no, @version_no, @lot_ser, @bin_no
		
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			-- 1. Move from pick table to dist group table
			TRUNCATE TABLE #dist_group
	
			INSERT INTO #dist_group (parent_serial_no, type, new_type, method, order_no,  order_ext,  part_no,
		                                 lot_ser,  bin_no, quantity, [function], custom_kit, qty_per, line_no) 
		       	VALUES                  (@carton_no, 'O1',  'N1', '01',  @order_no, @order_ext, @part_no, 
		                                 @lot_ser, @bin_no, 1, 'S',   NULL,      NULL,  @line_no)

			IF @@ERROR <> 0
			BEGIN
				CLOSE 	   serials_cursor
				DEALLOCATE serials_cursor
			        -- 'Unable to pack: Insert into #dist_group failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -102 AND language = @language 
			        RETURN -2
			END

			EXEC @sp_return = tdc_item_pack_group_sp
	
		    	If (@sp_return <> 0) 
			BEGIN
				CLOSE 	   serials_cursor
				DEALLOCATE serials_cursor
			        -- 'Unable to pack: tdc_item_pack_group_sp SP failed - '
				SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -103 AND language = @language 
				SELECT @error_msg = @error_msg + (SELECT TOP 1 err_msg FROM #dist_group)
			        RETURN -3
			END

			-- 2. Get formatted serial no
			EXEC @sp_return = tdc_format_serial_mask_sp @part_no, @serial_no, @formatted_serial OUTPUT, @error_msg OUTPUT
			
			IF @sp_return <> 1 
			BEGIN
				CLOSE      serials_cursor
				DEALLOCATE serials_cursor		
			        -- 'Unable to pack: tdc_format_serial_mask_sp SP failed. '
				SELECT @error_msg = (SELECT err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -104 AND language = @language) + @error_msg 
			        RETURN -3
			END
			
			-- 3. Insert new record into tdc_carton_detail_tx with a serial_no and qty_to_pack = 1
			INSERT INTO tdc_carton_detail_tx (order_no, order_ext, carton_no, tx_date, line_no, part_no, price, lot_ser, 
							  rec_date, bom_line_no, void, pack_qty, serial_no, status, version_no, 
							  tran_num, warranty_track, serial_no_raw, qty_to_pack, pack_tx)
			SELECT TOP 1
			       order_no, order_ext, carton_no, getdate(), line_no, part_no, price, lot_ser, getdate(), 
			       bom_line_no, void, 0, @formatted_serial, status, version_no, tran_num, warranty_track, 
			       @serial_no, 1, pack_tx
                          FROM tdc_carton_detail_tx 
                         WHERE carton_no = @carton_no
                           AND line_no   = @line_no
                           AND lot_ser   = @lot_ser

			IF @@ERROR <> 0
			BEGIN
				CLOSE 	   serials_cursor
				DEALLOCATE serials_cursor
			        -- 'Unable to pack: Insert into tdc_carton_detail_tx failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -105 AND language = @language 
			        RETURN -4
			END
	
			-- 4. Get vendor_sn, warranty_track, receipt_no
		    	SELECT @warranty_track = 0	
	    		SELECT @serial_flag    = vendor_sn, 
		               @warranty_track = warranty_track 
	                  FROM tdc_inv_list  (NOLOCK)
	                 WHERE part_no  = @part_no 
	                   AND location = @location

	   		-- Get the receipt            
		    	SELECT @receipt_no = ''
	    		SELECT @receipt_no = tran_num 
	                  FROM tdc_carton_detail_tx (NOLOCK) 
			 WHERE tran_num IS NOT NULL
                           AND ISNULL(serial_no, '') = ''
			   AND carton_no = @carton_no

			-- 5. Update carton details
		    	EXEC @sp_return = tdc_ins_upd_carton_det_rec @order_no, @order_ext, @carton_no, @line_no, @part_no, 1, 
							             @lot_ser, @formatted_serial, @serial_flag, @version_no,
								     @warranty_track, @receipt_no, @error_msg OUTPUT, 
								     @user_id, @location, @serial_no
		    	If (@sp_return <> 0) 
			BEGIN
				CLOSE      serials_cursor
				DEALLOCATE serials_cursor		
			        -- 'Unable to pack: tdc_ins_upd_carton_det_rec SP failed. ' 
				SELECT @error_msg = (SELECT err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -106 AND language = @language) + @error_msg 
			        RETURN -5
			END

			IF @not_using_orig_allocation = 'Y'
			BEGIN
				UPDATE tdc_carton_detail_tx
				   SET qty_to_pack = pack_qty
				 WHERE carton_no   = @carton_no
				   AND line_no     = @line_no
				   AND pack_qty    > qty_to_pack


				IF @@ERROR <> 0
				BEGIN
					CLOSE 	   serials_cursor
					DEALLOCATE serials_cursor
				        -- 'Unable to pack: Update tdc_carton_detail_tx failed.'
					SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -107 AND language = @language 
				        RETURN -6
				END
			END
			
			FETCH NEXT FROM serials_cursor INTO @serial_no, @version_no, @lot_ser, @bin_no
		END
		
		CLOSE      serials_cursor
		DEALLOCATE serials_cursor	

		-- Delete the original record with serial_no =  NULL
                DELETE FROM tdc_carton_detail_tx 
                 WHERE carton_no = @carton_no
                   AND line_no   = @line_no
                   AND ISNULL(serial_no, '') = ''
	END
	ELSE -- Part is not TDC serialized
	BEGIN
		
		IF @not_using_orig_allocation = 'Y'
		BEGIN
			-- Get Warranty
			SELECT @warranty_track = 
				ISNULL((SELECT top 1 warranty_track 
		                          FROM tdc_carton_detail_tx
					 WHERE carton_no = @carton_no
					   AND line_no   = @line_no), 0)
		END

		-- 1. Update carton details
	    	EXEC @sp_return = tdc_ins_upd_carton_det_rec @order_no, @order_ext, @carton_no, @line_no,  @part_no,        @qty, 
						     	     @lot_ser,  NULL,       'N',        NULL,      @warranty_track, NULL,
							     @error_msg OUTPUT, @user_id, @location, NULL
	    	If (@sp_return <> 0) 
		BEGIN
		        -- 'Unable to pack: tdc_ins_upd_carton_det_rec SP failed - '
			SELECT @error_msg = (SELECT err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -108 AND language = @language) + @error_msg
		        RETURN -7
		END

		IF @not_using_orig_allocation = 'Y'
		BEGIN
			UPDATE tdc_carton_detail_tx
			   SET qty_to_pack = pack_qty
			 WHERE carton_no   = @carton_no
			   AND line_no     = @line_no
			   AND pack_qty    > qty_to_pack

			IF @@ERROR <> 0
			BEGIN
			        -- 'Unable to pack: Update tdc_carton_detail_tx failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -109 AND language = @language 
			        RETURN -8
			END
		END	

		-- 2. Move from pick qty to dist group table
		TRUNCATE TABLE #dist_group

		INSERT INTO #dist_group (parent_serial_no, type, new_type, method, order_no,  order_ext,  part_no,
	                                 lot_ser,  bin_no, quantity, [function], custom_kit, qty_per, line_no) 
	       	VALUES                  (@carton_no, 'O1',  'N1', '01', @order_no, @order_ext, @part_no, 
	                                 @lot_ser, @bin_no, @qty,  'S', NULL,      NULL,       @line_no)
		IF @@ERROR <> 0
		BEGIN
		        -- 'Unable to pack: Insert into #dist_group failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -110 AND language = @language 
		        RETURN -9
		END
		
		EXEC @sp_return = tdc_item_pack_group_sp

	    	If (@sp_return <> 0) 
		BEGIN
		        -- 'Unable to pack: tdc_item_pack_group_sp SP failed - '
			SELECT @error_msg = (SELECT err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -111 AND language = @language) + (SELECT TOP 1 err_msg FROM #dist_group)
		        RETURN -10
		END

	END

	-- c) Update tdc_carton_tx
	UPDATE tdc_carton_tx
	   SET carton_type  = @carton_type,
               carton_class = @carton_class,
	       status       = 'O' 		-- Open
         WHERE carton_no    = @carton_no

	IF @@ERROR <> 0
	BEGIN
	        -- 'Unable to pack: Update tdc_carton_tx failed.'
		SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -112 AND language = @language 
	        RETURN -11
	END
		
	-- d) Change status of the carton
	UPDATE tdc_carton_detail_tx  SET status = 'O' WHERE carton_no = @carton_no
	IF @@ERROR <> 0
	BEGIN
	        -- 'Unable to pack: Update tdc_carton_detail_tx failed.'
		SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_pack_sp' AND err_no = -113 AND language = @language 
	        RETURN -12
	END
	
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_pack_sp] TO [public]
GO
