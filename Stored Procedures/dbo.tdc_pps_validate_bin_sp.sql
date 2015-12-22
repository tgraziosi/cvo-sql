SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_bin_sp]	
	@packing_flg	char(1),	
	@carton_no	int,
	@tote_bin	varchar(12),
	@order_no	int,
	@order_ext	int,
	@part_no	varchar(30), 
	@kit_item	varchar(30),
	@line_no	int,
	@location 	varchar(10),
	@lot_ser	varchar(25),
	@bin_no		varchar(12),
	@qty		decimal(20, 8) OUTPUT,
	@err_msg	varchar(255)OUTPUT

 
AS	

DECLARE @vendor_sn		char(1),
	@tdc_generated 		bit,
	@part			varchar(30),		 	 	 
	@ID_VERSION		int,
	@ID_QUANTITY		int,
	@ID_SCAN_SERIAL		int,
	@ID_PACK_UNPACK_SUCCESS int,
	@ID_AUTO_SCAN_QTY	int
 
----------------------------------------------------------------------------------------------------------------------------
--Set the values of the field indexes
----------------------------------------------------------------------------------------------------------------------------
	SELECT @ID_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'VERSION'


	SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'QTY'
	
	SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'SCAN_SERIAL'
	
	SELECT @ID_PACK_UNPACK_SUCCESS = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'PACK_UNPACK_SUCCESS'

	SELECT @ID_AUTO_SCAN_QTY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'AUTO_SCAN_QTY'


	IF (LTRIM(RTRIM(@bin_no)) = '') 
	BEGIN
		SELECT @err_msg = 'You must enter a bin'
		RETURN -1
	END

	--Is part a custom kit
	IF @kit_item = '' 
		SELECT @part = @part_no
	ELSE
		SELECT @part = @kit_item

	--if bin is putaway bin, it cannot be used in pick/unpick operations
	IF ((SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'putaway_ind') = 'Y') 
	BEGIN
		IF ((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'putaway_ind') = @bin_no)
                BEGIN
			SELECT @err_msg = 'Cannot pick/unpick from the putaway bin'
			RETURN -2
                END
	END

	--If packing
	IF @packing_flg = 'Y'
	BEGIN
        	IF NOT EXISTS(SELECT *
			        FROM tdc_pick_queue(NOLOCK)
			       WHERE trans = 'STDPICK'
			         AND trans_type_no = CAST(@order_no AS VARCHAR)
			         AND trans_type_ext = CAST(@order_ext AS VARCHAR)
			         AND line_no = @line_no
			         AND lot = @lot_ser
				 AND bin_no = @bin_no
			         AND tx_lock = '3')
		BEGIN
			SELECT @err_msg = 'Invalid bin.'
			RETURN -3
		END

	END --If packing
	ELSE --Not Packing
	BEGIN
		IF @bin_no = (SELECT value_str
			        FROM tdc_config (NOLOCK)
			       WHERE [function] = 'putaway_ind')
		BEGIN
			SELECT @err_msg = 'Invalid bin.'
			RETURN -4
		END

		IF NOT EXISTS(SELECT * FROM tdc_bin_master(NOLOCK)
			       WHERE location = @location
				 AND bin_no = @bin_no
				 AND usage_type_code = 'OPEN')
		BEGIN
			SELECT @err_msg = 'Invalid bin.'
			RETURN -5
		END
		
	END
	
	SELECT @vendor_sn = vendor_sn 
	  FROM tdc_inv_list (NOLOCK)
	 WHERE part_no  = @part
   	   AND location = @location
		 
	SELECT @tdc_generated = tdc_generated 
	  FROM tdc_inv_master (nolock)   
	 WHERE part_no = @part 

	--Serialized parts
	IF((@vendor_sn = 'O' AND @tdc_generated = 0)
	OR (@vendor_sn = 'I'))
	BEGIN
		RETURN @ID_SCAN_SERIAL
 	END

	IF EXISTS(SELECT * FROM tdc_inv_list (NOLOCK) WHERE location = @location AND part_no = @part AND ISNULL(version_capture, 0) != 0)
	AND @packing_flg = 'Y'
		RETURN @ID_VERSION
	ELSE
		IF EXISTS(SELECT * 
			    FROM inv_master (NOLOCK) 
		           WHERE part_no = @part
			     AND lb_tracking = 'Y' 
			     AND serial_flag = 1) 
		BEGIN
			SELECT @qty = 1
			RETURN @ID_AUTO_SCAN_QTY 
		END 
		ELSE
			RETURN @ID_QUANTITY

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_bin_sp] TO [public]
GO
