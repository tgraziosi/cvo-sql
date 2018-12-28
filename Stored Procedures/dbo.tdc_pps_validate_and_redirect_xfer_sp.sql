SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 19/12/2018 - Performance
CREATE PROCEDURE [dbo].[tdc_pps_validate_and_redirect_xfer_sp]
	--Input only fields
	@packing_flg		int,         --Flag for Packing/Unpacking.  Packing = 1
	@last_index		int,         --Index of the last field prior to this procedure
	@pcsn_flg		int,         --PCSN flag.  1 = Using PCSN
	@user_method		varchar(2),
	@serial_flg		int,         --Serialization flag.  1 = Using Serialization
	@reserved_0		int,	     --Pick-Pack On
	@auto_lot		varchar(25), --if not empty, use autolot with value
	@auto_bin		varchar(12), --if not empty, use autobin with value
	@Reserved1        	int,         
	@user_id         	varchar(50),
	@station_id		varchar(20),
	@auto_qty_flg		int,
	@Reserved2		int,
	@Reserved3		int,
	@cube_active		int,
	--Fields.  Declared as Input/Output in order to set initial values in the fields.
	@line_no         	int 		OUTPUT, 		
	@tote_bin		varchar(12)	OUTPUT, 		
	@xfer_no		int 		OUTPUT, 		
	@carton_no 		int 		OUTPUT, 		
	@total_cartons		int 		OUTPUT, 		
	@current_carton		int 		OUTPUT,		
	@PCSN			int 		OUTPUT, 		
	@part_no		varchar(30)   	OUTPUT, 	
	@Reserved5		varchar(30)   	OUTPUT,	  
	@location		varchar(10)   	OUTPUT, 	
	@uom			varchar(10)	OUTPUT,
	@lot_ser		varchar(25)   	OUTPUT, 	
	@bin_no			varchar(12)   	OUTPUT, 	
	@serial_no		varchar(40)   	OUTPUT, 	
	@version		varchar(40)   	OUTPUT,	
	@qty			decimal(20,8) 	OUTPUT, 	
	@serial_lot		varchar(25)	OUTPUT,
	@Reserved7		int 		OUTPUT,
	@Reserved8		int 		OUTPUT,
	--Output only params
	@line_cnt		int           	OUTPUT,
	@carton_status		varchar(25)   	OUTPUT,
	@err_msg		varchar(255)  	OUTPUT,
	@err_no			int           	OUTPUT,  
	@reserved9	  	int           OUTPUT,  
	@current_stage	 	varchar(11)   OUTPUT,	--INPUT/OUTPUT
	@carton_weight	 	decimal(20,8) OUTPUT	--INPUT/OUTPUT
AS
 
DECLARE
	@ret 			int,
	@cnt			int,
	@mask_code 		varchar(15),
	@language		varchar(10),
	@lReturn		int,
	@No_of_SN		int,

	--FIELD INDEXES TO BE RETURNED TO VB
	@ID_TOTE_BIN 	   	int,
	@ID_XFER_NO	   	int,
	@ID_CARTON_NO	   	int,
	@ID_TOTAL_CARTONS 	int,
	@ID_PCSN		int,
	@ID_PART_NO		int,
	@ID_LOCATION		int,
	@ID_UOM			int,
	@ID_LOT	 	 	int,
	@ID_BIN		 	int,
	@ID_QUANTITY		int,
	@ID_PACK_UNPACK_SUCCESS int,
	@ID_SCAN_SERIAL		int,
	@ID_SERIAL_LOT		int,
	@ID_SERIAL_VERSION	int
 
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

--Set the values of the field indexes
SELECT @ID_TOTE_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'TOTE_BIN'

SELECT @ID_XFER_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'XFER_NO'

SELECT @ID_CARTON_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'CARTON_NO'

SELECT @ID_TOTAL_CARTONS = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'TOTAL_CARTONS'

SELECT @ID_PCSN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PCSN'

SELECT @ID_PART_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PART_NO'

SELECT @ID_LOCATION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'LOCATION'

SELECT @ID_UOM = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'UOM'

SELECT @ID_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'LOT'

SELECT @ID_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'BIN'

SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'QUANTITY'

SELECT @ID_PACK_UNPACK_SUCCESS = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PACK_UNPACK_SUCCESS'

SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SCAN_SERIAL'

SELECT @ID_SERIAL_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SERIAL_LOT'

SELECT @ID_SERIAL_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SERIAL_VERSION'


--#####################################################################################
--If the current carton index = 0 after the validation of the carton,
--The user has generated a new carton.
--At this point, set current carton = carton count + 1
IF (@last_index > @ID_CARTON_NO) AND (@current_carton = 0)
BEGIN
	SELECT @cnt = COUNT(*) 
          FROM tdc_carton_tx (NOLOCK) -- v1.0
	 WHERE order_no  = @xfer_no
	   AND order_ext = 0
	   AND order_type = 'T'

	SELECT @current_carton = @cnt + 1	
END

--#####################################################################################
--In case user steps backwards, reinitialize the current carton and total cartons
IF (@last_index < @ID_CARTON_NO)  
BEGIN
	SELECT @current_carton = 0
	SELECT @total_cartons = 0
END

--#####################################################################################
IF @last_index = @ID_TOTE_BIN --Tote Bin
BEGIN
	EXEC @ret = tdc_pps_validate_tote_xfer_sp @packing_flg, @tote_bin, @xfer_no OUTPUT, @err_msg OUTPUT 	
 
	IF (@ret > 0 )
	BEGIN
		--Refresh the temp table for PPS display
		TRUNCATE TABLE #tdc_pack_out_item_xfer
		EXEC tdc_get_pack_out_item_list_sp @user_method, @xfer_no, 0, -1, 'T'
	END
	
	------------------------------------------------------------------------------
	-- Get the current stage number
	------------------------------------------------------------------------------
	IF NOT EXISTS(SELECT * FROM tdc_stage_numbers_tbl (NOLOCK)
		       WHERE active = 'Y')
	BEGIN
		EXEC tdc_increment_stage_sp ''
	END
	
	SELECT TOP 1 @current_stage = stage_no
	  FROM tdc_stage_numbers_tbl (NOLOCK)          
	 WHERE active = 'Y'                           
	 ORDER BY creation_date DESC                  


	SELECT @carton_weight = 0
	RETURN @ret
END

--#####################################################################################
IF @last_index = @ID_XFER_NO  
BEGIN
	EXEC @ret = tdc_pps_validate_order_xfer_sp  @packing_flg, @tote_bin, @xfer_no, @total_cartons OUTPUT, @err_msg OUTPUT
	
	IF (@ret > 0 )
	BEGIN
		--Refresh the temp table for PPS display
		TRUNCATE TABLE #tdc_pack_out_item_xfer 
		EXEC tdc_get_pack_out_item_list_sp @user_method, @xfer_no, 0, -1, 'T'
	END

	------------------------------------------------------------------------------
	-- Get the current stage number
	------------------------------------------------------------------------------
	IF (@current_stage IS NULL OR @current_stage = '')
	OR NOT EXISTS(SELECT * FROM tdc_stage_numbers_tbl (NOLOCK)
		       WHERE stage_no = @current_stage
		         AND active = 'Y')
	BEGIN
		IF NOT EXISTS(SELECT * FROM tdc_stage_numbers_tbl (NOLOCK)
			       WHERE active = 'Y')
		BEGIN
			EXEC tdc_increment_stage_sp ''
		END
		
		SELECT TOP 1 @current_stage = stage_no
		  FROM tdc_stage_numbers_tbl (NOLOCK)          
		 WHERE active = 'Y'                           
		 ORDER BY creation_date DESC       
	END

	SELECT @carton_weight = 0
	RETURN @ret
END

--#####################################################################################
IF @last_index = @ID_CARTON_NO  
BEGIN
	EXEC @ret = tdc_pps_validate_carton_xfer_sp  @pcsn_flg, @xfer_no, @carton_no, @total_cartons OUTPUT, 
						     @current_carton OUTPUT, @part_no OUTPUT, @err_msg OUTPUT
	IF (@ret > 0)
	BEGIN

		--Refresh the temp table for PPS display
		TRUNCATE TABLE #tdc_pack_out_item_xfer
		EXEC tdc_get_pack_out_item_list_sp @user_method, @xfer_no, 0, @carton_no, 'T'

		--If the current carton index = 0 after the validation of the carton,
		--The user has generated a new carton.
		--At this point, set current carton = carton count + 1
		IF (@current_carton = 0)
		BEGIN
			SELECT @cnt = COUNT(*)
 			  FROM tdc_carton_detail_tx a(NOLOCK),
			   tdc_carton_tx b(NOLOCK)
			 WHERE a.order_no  = @xfer_no
			   AND a.order_ext = 0
			   AND a.carton_no = b.carton_no
			   AND b.order_type = 'T'
			SELECT @current_carton = @cnt +1
		END
	END

	------------------------------------------------------------------------------
	-- Get the current stage number
	------------------------------------------------------------------------------
	IF EXISTS(SELECT * FROM tdc_stage_carton (NOLOCK)   
         	   WHERE carton_no = @carton_no)
	BEGIN
		SELECT @current_stage = stage_no 
		  FROM tdc_stage_carton (NOLOCK)   
                 WHERE carton_no = @carton_no 
	END
	ELSE 
	BEGIN
		IF NOT EXISTS(SELECT * FROM tdc_stage_numbers_tbl (NOLOCK)
			       WHERE active = 'Y')
		BEGIN
			EXEC tdc_increment_stage_sp ''
		END
		
		SELECT TOP 1 @current_stage = stage_no
		  FROM tdc_stage_numbers_tbl (NOLOCK)          
		 WHERE active = 'Y'                           
		 ORDER BY creation_date DESC       
	END

--	IF @cube_active = 1
--	BEGIN
--		INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning, carton_no, tran_no, tran_ext)
--					VALUES (@station_id, @user_id, 'VB', 'PPS', 'Start Carton', 1, @carton_no, @xfer_no, 0)  
--	END

	RETURN @ret
END

--#####################################################################################
IF @last_index = @ID_TOTAL_CARTONS --Total Cartons
BEGIN
	EXEC @ret = tdc_pps_validate_carton_total_xfer_sp  @xfer_no, 0,
			@total_cartons, @part_no OUTPUT, @err_no OUTPUT, @err_msg OUTPUT
	RETURN @ret
END


--#####################################################################################
IF @last_index = @ID_PART_NO --Part Number
BEGIN

	--Make sure carton_no is not '0'
	IF (@carton_no <= 0)
	BEGIN
		SELECT @err_msg = 'Invalid Carton Number'
		RETURN -1
	END

	--If carton is not open, do not go any further
	IF (@carton_status <> 'O' AND LTRIM(RTRIM(@carton_status)) <> '')
	BEGIN
		-- 'Carton is not open'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_and_redirect_xfer_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END

	SELECT @line_no = 0
	
	IF (@pcsn_flg <> 1)--Non PCS
	BEGIN
		EXEC @ret = tdc_pps_validate_part_xfer_sp 'Y', @packing_flg, @serial_flg, @tote_bin, @xfer_no, 
						 	  @carton_no, @auto_lot, @auto_bin, @line_no OUTPUT,
						 	  @location OUTPUT, @part_no OUTPUT, @serial_no OUTPUT, @uom OUTPUT, 
						 	  @lot_ser OUTPUT, @bin_no OUTPUT, @line_cnt OUTPUT, @err_msg OUTPUT 
	END

	IF (@ret = @ID_QUANTITY)
	BEGIN
		--If AutoQty, set quantity to 1 and begin pack or unpack
		IF (@auto_qty_flg = 1)
		BEGIN
			SELECT @qty = 1
			SELECT @last_index = @ID_QUANTITY
		END
		ELSE
			RETURN @ret

	END
	ELSE
		RETURN @ret
END

IF @last_index = @ID_UOM
BEGIN
	EXEC @ret = tdc_pps_validate_uom_xfer_sp @packing_flg, @carton_no, @tote_bin, @xfer_no, @auto_lot, @part_no OUTPUT, @line_no OUTPUT,
		 					       @location OUTPUT, @uom OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT
	IF (@ret = @ID_QUANTITY)
	BEGIN
		--If AutoQty, set quantity to 1 and begin pack or unpack
		IF (@auto_qty_flg = 1)
		BEGIN
			SELECT @qty = 1
			SELECT @last_index = @ID_QUANTITY
		END
		ELSE
			RETURN @ret

	END
	ELSE
		RETURN @ret
END

--#####################################################################################
IF @last_index = @ID_LOT -- Lot
BEGIN
	IF (@pcsn_flg = 0)
	BEGIN
		EXEC @ret = tdc_pps_validate_lot_xfer_sp @serial_flg, @packing_flg, @tote_bin, @xfer_no, @carton_no,
							 @line_no, @location,  @part_no,  @lot_ser, 
							 @bin_no OUTPUT, @qty OUTPUT, @err_msg OUTPUT

	END

	IF @ret = @ID_QUANTITY
	BEGIN	
		IF EXISTS(SELECT * 
			    FROM inv_master (NOLOCK) 
		           WHERE part_no = @part_no
			     AND lb_tracking = 'Y' 
			     AND serial_flag = 1) 
		BEGIN
			SELECT @qty = 1
			SELECT @last_index = @ID_QUANTITY
		END
		ELSE 
			RETURN @ID_QUANTITY
	END
	ELSE IF @auto_bin <> ''
	BEGIN
		IF (@auto_qty_flg = 1)
		BEGIN
			SELECT @qty = 1
			SELECT @last_index = @ID_QUANTITY
		END
		ELSE
			RETURN @ID_QUANTITY

	END
	ELSE
		RETURN @ret

	IF @ret < 0
		RETURN @ret 
	ELSE IF @ret = @ID_BIN 
	BEGIN
		RETURN @ret
	END
	ELSE IF @ret = @ID_QUANTITY
		SELECT @last_index = @ret

END

--#####################################################################################

IF @last_index = @ID_BIN --Bin
BEGIN
	IF (@pcsn_flg = 0)
	BEGIN
		EXEC @ret = tdc_pps_validate_bin_xfer_sp @packing_flg, @serial_flg, @xfer_no,
						        @part_no,      @location, @lot_ser,    @bin_no, 
						        @err_msg OUTPUT
	END

	IF @ret = @ID_QUANTITY
	BEGIN	
		IF EXISTS(SELECT * 
			    FROM inv_master (NOLOCK) 
		           WHERE part_no = @part_no
			     AND lb_tracking = 'Y' 
			     AND serial_flag = 1) 
		BEGIN
			SELECT @qty = 1
			SELECT @last_index = @ret
		END
		ELSE
			RETURN @ret
	END
	ELSE IF @auto_bin <> ''
	BEGIN

		IF (@auto_qty_flg = 1)
		BEGIN
			SELECT @qty = 1
			SELECT @last_index = @ID_QUANTITY
		END
		ELSE
			RETURN @ID_QUANTITY

	END
	ELSE
		RETURN @ret

END	

IF @last_index = @ID_SCAN_SERIAL
BEGIN
	exec @ret = dbo.tdc_pps_validate_serial_xfer_sp @packing_flg, @xfer_no, @carton_no, @part_no, @line_no, @location, @lot_ser output, @serial_no, @err_msg OUTPUT
	RETURN @ret 

END


IF @last_index = @ID_SERIAL_LOT
BEGIN
	EXEC @ret = tdc_pps_validate_serial_lot_xfer_sp @packing_flg, @carton_no, @xfer_no, @line_no, @part_no, @location, @serial_no, @lot_ser, @err_msg OUTPUT 
	RETURN @ret
END



--#####################################################################################
IF @last_index = @ID_QUANTITY --Quantity
BEGIN

	--Make sure carton_no is not '0'
	IF (@carton_no <= 0)
	BEGIN
		SELECT @err_msg = 'Invalid Carton Number'
		RETURN -1
	END

	--Revalidate the part, component, lot, bin, serial
	IF (@pcsn_flg <> 1)--Non PCS
	BEGIN
		EXEC @ret = tdc_pps_validate_part_xfer_sp 'N', @packing_flg, @serial_flg, @tote_bin, @xfer_no, 
						 	  @carton_no, @auto_lot, @auto_bin, @line_no OUTPUT,
						 	  @location OUTPUT, @part_no OUTPUT, @serial_no OUTPUT, @uom, 
						 	  @lot_ser OUTPUT, @bin_no OUTPUT, @line_cnt OUTPUT, @err_msg OUTPUT 
	END

	IF @ret < 0 RETURN -1

	IF @ret = @ID_SCAN_SERIAL
	BEGIN
		exec @ret = dbo.tdc_pps_validate_serial_xfer_sp @packing_flg, @xfer_no, @carton_no, @part_no, @line_no, @location, @lot_ser output, @serial_no, @err_msg OUTPUT
	END
	IF @ret < 0 RETURN -1

	IF @ret = @ID_SERIAL_LOT
	BEGIN
		EXEC @ret = tdc_pps_validate_serial_lot_xfer_sp @packing_flg, @carton_no, @xfer_no, @line_no, @part_no, @location, @serial_no, @lot_ser, @err_msg OUTPUT 

	END

	IF @ret < 0 RETURN -1


	IF (@pcsn_flg = 0 AND @ret = @ID_LOT)
	BEGIN
		EXEC @ret = tdc_pps_validate_lot_xfer_sp @serial_flg, @packing_flg, @tote_bin, @xfer_no, @carton_no,
							 @line_no, @location,  @part_no,  @lot_ser,  
							 @bin_no OUTPUT, @qty OUTPUT, @err_msg OUTPUT
	END
	
	IF @ret < 0 RETURN -1

	EXEC @ret = tdc_pps_validate_quantity_xfer_sp @packing_flg, @user_method, @tote_bin, @xfer_no,
						      @carton_no, @line_no, @location, @part_no, @uom,
						      @lot_ser, @bin_no, @qty OUTPUT, @err_msg OUTPUT

        --If failure, return error message
	IF (@ret = -1)
            RETURN -1

	--If packing, pack carton; else unpack carton
	IF (@packing_flg = 1)
	BEGIN

		IF EXISTS (SELECT * FROM tdc_inv_list (nolock) WHERE part_no = @part_no AND location = @location AND vendor_sn = 'O')  
		AND EXISTS (SELECT * FROM tdc_inv_master (nolock) WHERE part_no = @part_no AND tdc_generated = 1)
		BEGIN		
			SELECT @mask_code = mask_code FROM tdc_inv_master (nolock) WHERE part_no = @part_no			
		
			TRUNCATE TABLE #serial_no
			-- SET ARITHABORT OFF
			SELECT @No_of_SN = CAST(FLOOR(@qty) AS INT)
			-- SET ARITHABORT ON

			EXEC @lReturn = tdc_get_next_sn_sp @part_no, @No_of_SN, @location

			IF @lReturn < 0
			BEGIN
				-- 'Generate serial number failed!'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_and_redirect_xfer_sp' AND err_no = -102 AND language = @language 
				RETURN -1
			END
		
			SELECT @serial_no = MIN(serial_no) FROM #serial_no WHERE serial_no > @serial_no
			
			WHILE @serial_no IS NOT NULL
			BEGIN
				EXEC @ret = tdc_pps_pack_carton_xfer_sp @serial_flg, @user_id, @station_id, @tote_bin, @xfer_no, @carton_no,  
					       	        		@line_no, @location, @part_no, @lot_ser, @bin_no, 
									@serial_no, @version, 1, @user_method, @err_msg OUTPUT 				
			
				INSERT tdc_serial_no_track (location,  transfer_location, part_no, lot_ser,  mask_code, serial_no, serial_no_raw, IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, last_trans, last_tx_control_no, date_time, [User_id], ARBC_No)
						    SELECT @location, @location, 	 @part_no,   @lot_ser, @mask_code, @serial_no, @serial_no,    2,        'T',              'TPACK', @xfer_no, 	       'T', 	  'TPACK',     @xfer_no,   getdate(), @user_id, 	NULL						

				SELECT @serial_no = MIN(serial_no) FROM #serial_no WHERE serial_no > @serial_no
			END
		END
		ELSE
		BEGIN
			EXEC @ret = tdc_pps_pack_carton_xfer_sp @serial_flg, @user_id, @station_id, @tote_bin, @xfer_no, @carton_no,  
					       	        	@line_no, @location, @part_no, @lot_ser, @bin_no, 
								@serial_no, @version, @qty, @user_method, @err_msg OUTPUT 
		END

		--If failure, return error message
		IF (@ret <= 0)
			RETURN -1
		
		INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, 
				     tran_no, part_no, lot_ser, bin_no, 
				     location, quantity, data)
		VALUES (GETDATE(),@user_id, 'VB', 'PPS', 'Pack Carton Xfer', @xfer_no,
			@part_no, @lot_ser, @bin_no, @location, @qty, NULL) 

	--	IF @cube_active = 1
	--	BEGIN	
			-- added on 8-13-01 by Trevor Emond for Analysis Services
	--		INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning, carton_no, 
	--				  tran_no, tran_ext, location, part_no, bin_no, quantity)
	--		VALUES (@station_id, @user_id, 'VB', 'PPS', 'Pack Carton', 0, @carton_no, @xfer_no, 0,
	--			  	@location, @part_no, @bin_no, @qty)  
	--	END
                                                                                                                                                                                                                                                      

	END
	ELSE --Unpacking
	BEGIN

		EXEC @ret = tdc_pps_unpack_carton_xfer_sp @serial_flg, @user_id, @tote_bin, @xfer_no, 
						          @carton_no, @line_no, @part_no, @location, @lot_ser, @bin_no,
						          @serial_no, @version, @qty, @user_method, @err_msg OUTPUT
		IF (@ret = -1)
			RETURN -1

		INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, 
				     tran_no, part_no, lot_ser, bin_no, 
				     location, quantity, data)
		VALUES (GETDATE(),@user_id, 'VB', 'PPS', 'Unpack Carton', @xfer_no, 
			@part_no, @lot_ser, @bin_no, @location, @qty, NULL)  

	--	IF @cube_active = 1
	--	BEGIN
			-- added on 8-13-01 by Trevor Emond for Analysis Services
	--		INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning, carton_no, 
	--				  tran_no, tran_ext, location, part_no, bin_no, quantity)
	--		VALUES (@station_id, @user_id, 'VB', 'PPS', 'Unpack Carton', 0, @carton_no, @xfer_no, 0,
	--			  	@location, @part_no, @bin_no, @qty)  
	--	END
  
	END

	IF (@ret = -1)
		RETURN -1

	ELSE
	BEGIN				
		--Refresh the temp table for PPS display
		TRUNCATE TABLE #tdc_pack_out_item_xfer
		EXEC tdc_get_pack_out_item_list_sp @user_method, @xfer_no, 0, @carton_no, 'T'

		RETURN @ID_PACK_UNPACK_SUCCESS
	END
END

--If nothing has returned by this point, there is an error in VB
-- @err_msg = 'Invalid visual interface index'
SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_and_redirect_xfer_sp' AND err_no = -103 AND language = @language 

RETURN -1
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_and_redirect_xfer_sp] TO [public]
GO
