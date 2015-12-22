SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_lot_xfer_sp]
	@serial_flg		int,
	@packing_flg		int,
	@tote_bin		varchar(12),
	@xfer_no		int,
	@carton_no		int,
	@line_no        	int,
	@location		varchar(10),	
	@part_no		varchar(30),
	@lot_ser		varchar(25),
	@bin_no			varchar(12) 	OUTPUT,
	@qty			decimal(20,8)	OUTPUT,	
	@err_msg		varchar(255) 	OUTPUT
AS 

DECLARE @ret			int,
	@vendor_sn 		char(1),
	@tdc_generated		bit,
	@language		varchar(10),
	--FIELD INDEXES TO BE RETURNED TO VB	
	@ID_LOT	 	 	int,
	@ID_BIN		 	int,
	@ID_QUANTITY		int,
	@ID_SCAN_SERIAL		int,
	@ID_PACK_UNPACK_SUCCESS int

SELECT @vendor_sn = 'N'
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

--Set the values of the field indexes
SELECT @ID_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'LOT'

SELECT @ID_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'BIN'

SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'QUANTITY'

SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SCAN_SERIAL'

SELECT @ID_PACK_UNPACK_SUCCESS = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PACK_UNPACK_SUCCESS'


	IF (LTRIM(RTRIM(@lot_ser)) = '')
	BEGIN
		-- @err_msg = 'You must enter a lot'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_lot_xfer_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END	
	
-- SCR #37905
-- 	IF @packing_flg = 0 -- unpacking
-- 	BEGIN
		IF (@packing_flg = 1)--Packing
		BEGIN
			--Ensure lot exist 
			IF NOT EXISTS(SELECT *
     					FROM lot_bin_xfer (NOLOCK)  
     				       WHERE tran_no    = @xfer_no
					 AND tran_ext   = 0
					 AND location   = @location
					 AND part_no 	= @part_no
     					 AND lot_ser 	= @lot_ser)
			BEGIN
				-- @err_msg = 'Invalid Lot'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_lot_xfer_sp' AND err_no = -102 AND language = @language 
				RETURN -1
			END

			IF NOT EXISTS(SELECT *
					FROM tdc_dist_item_pick (NOLOCK)  
	 			       WHERE order_no   = @xfer_no
	         			 AND order_ext  = 0
	         			 AND line_no    = @line_no
	         			 AND lot_ser    = @lot_ser
	         			 AND part_no	= @part_no
					 AND quantity > 0
					 AND [function] = 'T')					 
			BEGIN
				-- @err_msg = 'Invalid Lot'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_lot_xfer_sp' AND err_no = -102 AND language = @language 
				RETURN -1
			END	

		END--PACKING
		ELSE --Unpacking
		BEGIN
    			IF NOT EXISTS(SELECT *
					FROM tdc_carton_detail_tx a(NOLOCK),
					     tdc_carton_tx b(NOLOCK) 
             			       WHERE a.line_no    = @line_no
             				 AND a.lot_ser    = @lot_ser
             				 AND a.order_no   = @xfer_no
             				 AND a.order_ext  = 0
					 AND a.carton_no  = b.carton_no
					 AND b.order_type = 'T')
			BEGIN
				-- @err_msg = 'Invalid Lot'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_lot_xfer_sp' AND err_no = -102 AND language = @language 
				RETURN -1
			END

		END --Packing/Unpacking
	
-- 	END --Using Pickpack
-- 	ELSE --Not Pickpack, packing
-- 	BEGIN
-- 		IF NOT EXISTS(SELECT *
-- 				FROM tdc_dist_item_pick (NOLOCK)  
--  			       WHERE order_no   = @xfer_no
--          			 AND order_ext  = 0
--          			 AND line_no    = @line_no
--          			 AND lot_ser    = @lot_ser
--          			 AND part_no	= @part_no
-- 				 AND [function] = 'T')
-- 
-- 		BEGIN
-- 			-- @err_msg = 'Invalid Lot'
-- 			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_lot_xfer_sp' AND err_no = -102 AND language = @language 
-- 			RETURN -1
-- 		END
-- 	END--Not Pickpack
		
	--If epicor serialized part, the lot is the serial number; pack the item.
	IF EXISTS(SELECT * 
		    FROM inv_master (NOLOCK) 
	           WHERE part_no = @part_no
		     AND lb_tracking = 'Y' 
		     AND serial_flag = 1) 
	BEGIN	
		IF @packing_flg = 1
		BEGIN
			SELECT @bin_no = bin_no
			  FROM lot_bin_xfer (NOLOCK)
			 WHERE tran_no   = @xfer_no
			   AND tran_ext  = 0
			   AND location  = @location
			   AND part_no   = @part_no
			   AND lot_ser   = @lot_ser
			
			SELECT @qty = 1
			RETURN @ID_QUANTITY
		END 
		ELSE --UNPACKING
		BEGIN
			RETURN @ID_BIN
		END
	END

	--If pick/pack, user has to input the bin
	--if not, the bin has already been specified in the pick operation
	--if no error, move to bin field.
	
	--Retrieve the bin 				
	EXEC tdc_pps_get_bin_xfer_sp @packing_flg, @tote_bin, @xfer_no, @carton_no, @line_no, 
				@location, @part_no, @lot_ser, @bin_no OUTPUT
 
	-- SCR #37905
 	IF @bin_no IS NOT NULL RETURN @ID_BIN

	--If using serialization, return the serial scan code.
	--If not, move to the quantity field
	IF(@serial_flg = 1)
	BEGIN
		SELECT @vendor_sn = vendor_sn 
		  FROM tdc_inv_list (NOLOCK)
		 WHERE part_no  = @part_no
	   	   AND location = @location
			 
		SELECT @tdc_generated = tdc_generated 
		  FROM tdc_inv_master (nolock)   
		 WHERE part_no = @part_no 
	
		IF @packing_flg = 0 AND @vendor_sn != 'N'
			RETURN @ID_SCAN_SERIAL

		IF(@vendor_sn = 'I') OR ((@vendor_sn = 'O') AND (@tdc_generated = 0))
			RETURN @ID_SCAN_SERIAL
	END

	RETURN @ID_QUANTITY

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_lot_xfer_sp] TO [public]
GO
