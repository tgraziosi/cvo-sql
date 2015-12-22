SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_uom_xfer_sp]	
	@packing_flg	int,
	@carton_no	int,
	@tote_bin	varchar(12),
	@xfer_no	int,
	@auto_lot	varchar(25),
	@part_no	varchar(30)  OUTPUT,
	@line_no	int	     OUTPUT,		
	@location	varchar(10)  OUTPUT,	
	@uom 		varchar(10)  OUTPUT,
	@lot_ser	varchar(25)  OUTPUT,
	@bin_no		varchar(12)  OUTPUT,
	@err_msg	varchar(255) OUTPUT
AS	

DECLARE @order_uom		varchar(10),
	@vendor_sn		char(1),
	@tdc_generated 		bit,
	@lb_tracking		char(1),	
	@ret			int,
	@base_uom		varchar(10),
	@cnt			int,

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


	IF (LTRIM(RTRIM(@uom)) = '')
	BEGIN
		SELECT @err_msg = 'You must enter a UOM'
		RETURN -1
	END	

	SELECT @order_uom = uom
	  FROM xfer_list (NOLOCK)
	 WHERE xfer_no = @xfer_no
	   AND line_no = @line_no
	 
	
	IF @uom != @order_uom
	BEGIN
		IF NOT EXISTS(SELECT * FROM uom_list (NOLOCK) WHERE uom = @uom)
		BEGIN
			SELECT @err_msg = 'Invalid UOM'
			RETURN -2
		END
	
		SELECT @base_uom = uom FROM inv_master(NOLOCK) where part_no = @part_no


	
		IF NOT EXISTS(SELECT * FROM uom_table (NOLOCK) WHERE item IN( @part_no, 'STD' ) AND std_uom = @base_uom AND alt_uom = @uom)
		BEGIN
			SELECT @err_msg = 'UOM conversion does not exist'
			RETURN -3
		END
	END
	  
	-- Get lb_tracking
	SELECT @lb_tracking = LB_Tracking
	  FROM inv_master (NOLOCK)
	 WHERE part_no = @part_no


	IF (@lb_tracking = 'Y')
	BEGIN
		--If autolot, fill in the lot field
		IF (@auto_lot <> '')
		BEGIN
			SELECT @lot_ser = @auto_lot
		END
		ELSE --Move focus to the lot field
		BEGIN

			--If only one lot, set it to default
			IF @packing_flg = 1
			BEGIN
				SELECT @cnt = COUNT(DISTINCT a.lot_ser)
				  FROM tdc_dist_item_pick a (NOLOCK), 
				       lot_bin_xfer b(NOLOCK)
				 WHERE a.order_no   = b.tran_no
				   AND a.[function] = 'T'
				   AND a.order_ext  = b.tran_ext
				   AND a.line_no    = b.line_no
				   AND a.bin_no     = b.bin_no
				   AND a.lot_ser    = b.lot_ser
				   AND a.part_no    = b.part_no
				   AND a.order_no   = @xfer_no
				   AND a.order_ext  = 0
				   AND b.location   = @location
				   AND a.part_no    = @part_no
				   AND a.line_no    = @line_no

				IF @cnt = 1
				BEGIN
					SELECT DISTINCT @lot_ser = a.lot_ser 
					  FROM tdc_dist_item_pick a (NOLOCK), 
					       lot_bin_xfer       b (NOLOCK)
					 WHERE a.order_no   = b.tran_no
					   AND a.[function] = 'T'
					   AND a.order_ext  = b.tran_ext
					   AND a.line_no    = b.line_no
					   AND a.bin_no     = b.bin_no
					   AND a.lot_ser    = b.lot_ser
					   AND a.part_no    = b.part_no
					   AND a.order_no   = @xfer_no
					   AND a.order_ext  = 0
					   AND b.location   = @location
					   AND a.part_no    = @part_no
					   AND a.line_no    = @line_no
				END
				
			END
			ELSE --UNPACKING
			BEGIN
				SELECT @cnt = COUNT(DISTINCT a.lot_ser)
				  FROM tdc_carton_detail_tx a(NOLOCK),
				       tdc_carton_tx b (NOLOCK)
				 WHERE a.carton_no  = @carton_no
				   AND a.carton_no  = b.carton_no
				   AND a.line_no    = @line_no
				   AND a.part_no    = @part_no
				   AND b.order_type = 'T'

				IF @cnt = 1
				BEGIN
					SELECT DISTINCT @lot_ser = a.lot_ser 
					  FROM tdc_carton_detail_tx a (NOLOCK),
					       tdc_carton_tx        b (NOLOCK)
					 WHERE a.carton_no   = @carton_no
					   AND a.carton_no   = b.carton_no
					   AND a.line_no     = @line_no
					   AND a.part_no     = @part_no
					   AND b.order_type  = 'T'		
				END
			END	
		
				RETURN @ID_LOT
		END

		EXEC tdc_pps_get_bin_xfer_sp @packing_flg, @tote_bin, @xfer_no, @carton_no, @line_no, 
			 		     @location, @part_no, @lot_ser, @bin_no OUTPUT

		IF (@vendor_sn = 'I') OR ((@tdc_generated = 0) AND (@vendor_sn = 'O'))
			RETURN @ID_SCAN_SERIAL
	END

	RETURN @ID_QUANTITY

 
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_uom_xfer_sp] TO [public]
GO
