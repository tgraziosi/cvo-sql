SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_uom_sp]	
	@is_packing	char(1),
	@is_3_step	char(1),
	@carton_no	int,
	@tote_bin	varchar(12),
	@order_no	int,
	@order_ext	int,
	@auto_lot	varchar(25),
	@auto_bin	varchar(25),
	@tran_id	int,
	@part_no	varchar(30)  OUTPUT,
	@kit_item	varchar(30)  OUTPUT,
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
	@io_count		int,
	@lb_tracking		char(1),	
	@packing_flg		int,
	@ret			int,
	@part			varchar(30),
	@base_uom		varchar(10),

	--FIELD INDEXES TO BE RETURNED TO VB
	@ID_KIT_ITEM		int,		
	@ID_LOT	 	 	int,
	@ID_BIN		 	int,
	@ID_VERSION		int,
	@ID_QUANTITY		int,
	@ID_LINE_NO		int,
	@ID_SCAN_SERIAL		int

	----------------------------------------------------------------------------------------------------------------------------
	--Set the values of the field indexes
	----------------------------------------------------------------------------------------------------------------------------
	SELECT @ID_KIT_ITEM = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'KIT_ITEM'
	
	SELECT @ID_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'LOT'
	
	SELECT @ID_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'BIN'
	
	SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'QTY'
	
	SELECT @ID_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'VERSION'

	SELECT @ID_LINE_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'LINE_NO'

	SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'SCAN_SERIAL'


	IF (LTRIM(RTRIM(@uom)) = '')
	BEGIN
		SELECT @err_msg = 'You must enter a UOM'
		RETURN -1
	END	

 
 	IF ISNULL(@kit_item, '') = '' 
	BEGIN
		SELECT @part = @part_no

		SELECT @order_uom = uom
		  FROM ord_list (NOLOCK)
		 WHERE order_no = @order_no
		   AND order_ext = @order_ext
		   AND line_no = @line_no
	END
	ELSE
	BEGIN
		SELECT @part = @kit_item

		SELECT @order_uom = uom
		  FROM ord_list_kit (NOLOCK)
		 WHERE order_no = @order_no
		   AND order_ext = @order_ext
		   AND line_no = @line_no
		   AND part_no = @kit_item
	END
	
	IF @uom != @order_uom
	BEGIN

		IF NOT EXISTS(SELECT * FROM uom_list (NOLOCK) WHERE uom = @uom)
		BEGIN
			SELECT @err_msg = 'Invalid UOM'
			RETURN -2
		END
	
		SELECT @base_uom = uom FROM inv_master(NOLOCK) where part_no = @part

		IF @base_uom <> @uom
		BEGIN	
			IF NOT EXISTS(SELECT * FROM uom_table (NOLOCK) WHERE item IN( @part, 'STD' ) AND std_uom = @base_uom AND alt_uom = @uom)
			BEGIN
				SELECT @err_msg = 'UOM conversion does not exist'
				RETURN -3
			END
		END
	END
	 
 

	--------------------------------------------------------------------------------------	
	--Determine which field to set focus to 
	--------------------------------------------------------------------------------------		 
 
	SELECT @vendor_sn = vendor_sn 
	  FROM tdc_inv_list (nolock)
	 WHERE part_no  = @part
   	   AND location = @location
		 
	SELECT @tdc_generated = tdc_generated 
	  FROM tdc_inv_master (nolock)   
	 WHERE part_no = @part

	SET @io_count = 0

	IF @is_packing = 'Y'
		SET @io_count = 1

	--if lot/bin tracked then 
	SELECT @lb_tracking = lb_tracking
	  FROM inv_master (NOLOCK)
	 WHERE part_no = @part

	 
 
	IF (@lb_tracking = 'Y')
	BEGIN
		--If autolot, fill in the lot field
		IF (@auto_lot <> '')
		BEGIN
			SELECT @lot_ser = @auto_lot
		END
		ELSE --Move focus to the lot field
		BEGIN				 														
			RETURN @ID_LOT
		END

		IF @is_packing = 'Y'
			SELECT @packing_flg = 1
		ELSE
			SELECT @packing_flg = 0

		IF @auto_bin <> ''
		BEGIN
			SELECT @bin_no = @auto_bin
		END
		ELSE
		BEGIN
			IF @is_3_step = 'Y' AND @is_packing = 'Y'
			BEGIN
				RETURN @ID_BIN
			END
			ELSE
				EXEC tdc_pps_get_bin_sp @is_packing, @carton_no, @tote_bin, @order_no, @order_ext, @line_no, @part, @kit_item, @location, @lot_ser, @bin_no OUTPUT
		END
	END

	IF EXISTS(SELECT * FROM tdc_inv_list (NOLOCK) WHERE location = @location AND part_no = @part AND ISNULL(version_capture, 0) != 0)
	AND @is_packing = 'Y'
		RETURN @ID_VERSION
	ELSE
		RETURN @ID_QUANTITY

 
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_uom_sp] TO [public]
GO
