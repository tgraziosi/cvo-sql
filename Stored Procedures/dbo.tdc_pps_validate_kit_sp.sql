SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_kit_sp]	
	@is_packing	char(1),
	@is_3_step	char(1),
	@carton_no	int,
	@tote_bin	varchar(12),
	@order_no	int,
	@order_ext	int,
	@auto_lot	varchar(25),
	@auto_bin	varchar(25),
	@part_no	varchar(30),
	@kit_item	varchar(30) OUTPUT,
	@line_no	int	     OUTPUT,			
	@uom		varchar(10)  OUTPUT,
	@lot_ser	varchar(25)  OUTPUT,
	@bin_no		varchar(12)  OUTPUT,
	@err_msg	varchar(255) OUTPUT

AS	

DECLARE @vendor_sn		char(1),
	@tdc_generated 		bit,
	@part			varchar(30),	
	@io_count		int,
	@lb_tracking		char(1),	
	@packing_flg		int,
	@picked			decimal(20, 8),
	@packed			decimal(20, 8),
	@location		varchar(10),

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
	
	SELECT @ID_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'VERSION'

	SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'QTY'
	
	SELECT @ID_LINE_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'LINE_NO'
	
	SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'SCAN_SERIAL'


	IF (LTRIM(RTRIM(@kit_item)) = '')
	BEGIN
		SELECT @err_msg = 'You must enter a kit part number'
		RETURN -1
	END

	-- UPC Logic
	IF NOT EXISTS(SELECT * FROM ord_list_kit(NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @kit_item)
		EXEC tdc_get_part_from_uom_sp @kit_item output, @uom output


	IF NOT EXISTS(SELECT * 
			FROM inventory (NOLOCK)
		       WHERE part_no = @kit_item)
	BEGIN
		SELECT @err_msg = 'Invalid Kit Part Number'
		RETURN -4
	END

	IF NOT EXISTS(SELECT * 
			FROM inventory a (NOLOCK),
			     ord_list_kit  b (NOLOCK)
		       WHERE a.part_no   = @kit_item
			 AND b.order_no  = @order_no
			 AND b.order_ext = @order_ext
			 AND b.line_no   = @line_no
			 AND b.part_no   = a.part_no)
	BEGIN
		SELECT @err_msg = 'Invalid Kit Part Number'
		RETURN -5
	END	 

	--------------------------------------------------------------------------------------	
	--First Do validation
	--------------------------------------------------------------------------------------			
  
	--If not in pick/pack mode, make sure that the part has been picked
	IF @is_packing = 'Y'
	BEGIN
		IF @is_3_step = 'N'
		BEGIN
			SELECT @picked = 0, @packed = 0
			SELECT @picked = kit_picked 
			  FROM tdc_ord_list_kit (NOLOCK)
			 WHERE order_no = @order_no
		 	   AND order_ext = @order_ext
			   AND line_no = @line_no
			   AND kit_part_no = @kit_item

		 	SELECT @packed = SUM(pack_qty)
			  FROM tdc_carton_detail_tx (NOLOCK)
			 WHERE order_no = @order_no
			   AND order_ext = @order_ext
			   AND line_no = @line_no
			   AND part_no = @kit_item
			 GROUP BY order_no, order_ext, line_no, part_no

			IF @picked <= @packed
			BEGIN
				SELECT @err_msg = 'Kit item has not been picked'
				RETURN -10
			END
		END
		ELSE -- 3 step
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) 
				       WHERE trans = 'STDPICK'
					 AND CAST(trans_type_no AS INT) = @order_no
					 AND CAST(trans_type_ext AS INT) = @order_ext
					 AND tx_lock = '3'
					 AND line_no = @line_no
					 AND part_no = @kit_item)
			BEGIN
				SELECT @err_msg = 'Invalid kit item for queue tran id'
				RETURN -11
			END
		END

		--If packing from tote bins, verify that the part is in the tote
		IF @tote_bin <> '' 
		BEGIN				
			IF NOT EXISTS (SELECT * 
					 FROM tdc_tote_bin_tbl a(NOLOCK),
					      ord_list_kit     b(NOLOCK)   
					WHERE a.order_no   = @order_no
					  AND a.order_ext  = @order_ext
					  AND a.line_no    = @line_no
					  AND a.location   = b.location
					  AND a.bin_no     = @tote_bin
					  AND a.order_type = 'S'
					  AND b.order_no   = a.order_no
					  AND b.order_ext  = a.order_ext
					  AND b.location   = a.location
					  AND b.line_no    = a.line_no
					  AND b.part_no    = a.part_no)
			BEGIN
				SELECT @err_msg = 'Kit Item not found in the tote bin'
				RETURN -13
			END	
		END
	END
	ELSE IF @is_packing = 'N'
	BEGIN
		IF NOT EXISTS(SELECT *
				FROM tdc_carton_detail_tx (NOLOCK)
			       WHERE carton_no = @carton_no
				 AND part_no   = @kit_item)
		BEGIN
			SELECT @err_msg = 'Kit Item has not been packed'
			RETURN -14
		END
	END
	
	--------------------------------------------------------------------------------------	
	--Determine which field to set focus to 
	--------------------------------------------------------------------------------------		
 	SELECT @location = location
	  FROM ord_list_kit (nolock)
	 WHERE order_no = @order_no
	   AND order_ext = @order_ext
	   AND line_no = @line_no

	SELECT @vendor_sn = vendor_sn 
	  FROM tdc_inv_list (nolock)
	 WHERE part_no  = @kit_item
   	   AND location = @location
		 
	SELECT @tdc_generated = tdc_generated 
	  FROM tdc_inv_master (nolock)   
	 WHERE part_no = @kit_item

	SET @io_count = 0

	IF @is_packing = 'Y'
		SET @io_count = 1	 

	--if lot/bin tracked then 
	SELECT @lb_tracking = lb_tracking
	  FROM inv_master (NOLOCK)
	 WHERE part_no = @kit_item	

	IF ISNULL(@uom, '') = ''
	BEGIN
		SELECT @uom = uom	
		  FROM ord_list_kit(NOLOCK) 
		WHERE order_no = @order_no
		 AND order_ext = @order_ext
		 AND line_no = @line_no
		 AND part_no = @kit_item
	END

	--Serialized parts
	IF((@vendor_sn = 'O' AND @tdc_generated = 0)
	OR (@vendor_sn = 'I'))
	BEGIN
		IF @is_packing = 'Y'
		BEGIN
			IF((@is_3_step = 'Y' AND @lb_tracking = 'N')
	--		OR (@vendor_sn = 'I' AND @is_3_step = 'N'))  Jim On 12/03/07
			OR @is_3_step = 'N')
			BEGIN
				RETURN @ID_SCAN_SERIAL
			END		
		END
		ELSE
		BEGIN
			RETURN @ID_SCAN_SERIAL
		END
	END

	IF (@lb_tracking = 'Y')
	BEGIN
		--If autolot, fill in the lot field
		IF (@auto_lot <> '')
		BEGIN
			SELECT @lot_ser = @auto_lot
--			IF EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'auto_lot_part' AND active = 'Y')
--				SELECT @lot_ser = ISNULL((SELECT auto_lot FROM tdc_inv_master (nolock) WHERE part_no = @kit_item), @auto_lot)
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
				EXEC tdc_pps_get_bin_sp @is_packing, @carton_no, @tote_bin, @order_no, @order_ext, @line_no, @part_no, @kit_item, @location, @lot_ser, @bin_no OUTPUT
		END
	END 

	IF EXISTS(SELECT * FROM tdc_inv_list (NOLOCK) WHERE location = @location AND part_no = @kit_item AND ISNULL(version_capture, 0) != 0)
	AND @is_packing = 'Y'
		RETURN @ID_VERSION
	ELSE
		RETURN @ID_QUANTITY

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_kit_sp] TO [public]
GO
