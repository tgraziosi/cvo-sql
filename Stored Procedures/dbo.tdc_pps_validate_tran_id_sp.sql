SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_tran_id_sp]	
	@is_packing	char(1),
	@tote_bin	varchar(12),
	@order_no	int,
	@order_ext	int,
	@tran_id	int,
	@part_no	varchar(30)  OUTPUT,
	@kit_item	varchar(30)  OUTPUT,
	@uom		varchar(10)  OUTPUT,
	@line_no	int	     OUTPUT,		
	@location	varchar(10)  OUTPUT,	
	@lot_ser	varchar(25)  OUTPUT,
	@bin_no		varchar(12)  OUTPUT,
	@err_msg	varchar(255) OUTPUT

AS

DECLARE @vendor_sn		char(1),
	@tdc_generated 		bit,
	@part			varchar(30),	
	@io_count		int,
	@ID_PART_NO		int,
	@ID_KIT_ITEM		int,		
	@ID_LOCATION		int,
	@ID_LOT	 	 	int,
	@ID_BIN		 	int,
	@ID_QUANTITY		int,
	@ID_SCAN_SERIAL		int,
	@ID_VERSION		int

 
----------------------------------------------------------------------------------------------------------------------------
--Set the values of the field indexes
----------------------------------------------------------------------------------------------------------------------------
SELECT @ID_PART_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'PART_NO'

SELECT @ID_KIT_ITEM = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'KIT_ITEM'

SELECT @ID_LOCATION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'LOCATION'

SELECT @ID_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'LOT'

SELECT @ID_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'BIN'

SELECT @ID_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'VERSION'

SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'QTY'

SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'SCAN_SERIAL'


-----------------------------------------------------------------------------------
--If nothing is entered for Q tran id, move focus to the part field
-----------------------------------------------------------------------------------
IF @tran_id = 0
BEGIN
	RETURN @ID_PART_NO
END

-----------------------------------------------------------------------------------
--Validate the qtx
-----------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) 
	       WHERE trans = 'STDPICK'
		 AND tran_id = @tran_id
		 AND CAST(trans_type_no AS INT) = @order_no
		 AND CAST(trans_type_ext AS INT) = @order_ext
		 AND tx_lock = '3')
BEGIN
	-----------------------------------------------------------------------------------
	-- If here, qtx is invalid.  find out why.
	-----------------------------------------------------------------------------------
	IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) 
		       WHERE trans = 'STDPICK'
			 AND tran_id = @tran_id
			 AND CAST(trans_type_no AS INT) = @order_no
			 AND CAST(trans_type_ext AS INT) = @order_ext
			 AND tx_lock != '3')
	BEGIN
		SELECT @err_msg = 'Queue transaction is not yet released'
		RETURN -1
	END

	ELSE IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) 
		        WHERE trans = 'STDPICK'
			  AND tran_id = @tran_id
			  AND tx_lock = '3')
	BEGIN
		SELECT @err_msg = 'Invalid queue transaction for order/ext'
		RETURN -2
	END
	ELSE
	BEGIN
		SELECT @err_msg = 'Invalid queue tran ID'
		RETURN -3
	END

END
 
-----------------------------------------------------------------------------------
--Get the information from the queue
-----------------------------------------------------------------------------------
SELECT @part = part_no, @location = location, @lot_ser = lot, @line_no = line_no, @bin_no = bin_no
  FROM tdc_pick_queue (NOLOCK)
 WHERE trans = 'STDPICK'
   AND tran_id = @tran_id
   AND CAST(trans_type_no AS INT) = @order_no
   AND CAST(trans_type_ext AS INT) = @order_ext
   AND tx_lock = '3'

-- Get the UOM
SELECT @uom = uom FROM inv_master(NOLOCK) WHERE part_no = @part
 
-----------------------------------------------------------------------------------
--Determine if the part is a kit item
-----------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM ord_list_kit (NOLOCK)
	   WHERE order_no  = @order_no
	     AND order_ext = @order_ext
	     AND line_no   = @line_no)
BEGIN
	SELECT @part_no = part_no 
	  FROM ord_list (NOLOCK)
	 WHERE order_no  = @order_no
	   AND order_ext = @order_ext
	   AND line_no   = @line_no
	SELECT @kit_item = @part
END
ELSE
BEGIN
	SELECT @part_no = @part
END

SELECT @vendor_sn = vendor_sn 
  FROM tdc_inv_list (nolock)
 WHERE part_no  = @part_no
	   AND location = @location
	 
SELECT @tdc_generated = tdc_generated 
  FROM tdc_inv_master (nolock)   
 WHERE part_no = @part_no


--Serialized parts
IF (@vendor_sn != 'N') AND ((@tdc_generated = 0) OR (@vendor_sn = 'I'))
	RETURN @ID_SCAN_SERIAL

IF EXISTS(SELECT part_no FROM inv_master (NOLOCK) WHERE part_no = @part AND lb_tracking = 'Y')
AND ISNULL(@bin_no, '') = ''
	RETURN @ID_BIN
ELSE
	IF EXISTS(SELECT * FROM tdc_inv_list (NOLOCK) WHERE location = @location AND part_no = @part_no AND ISNULL(version_capture, 0) != 0)
	AND @is_packing = 'Y'
		RETURN @ID_VERSION
	ELSE
		RETURN @ID_QUANTITY

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_tran_id_sp] TO [public]
GO
