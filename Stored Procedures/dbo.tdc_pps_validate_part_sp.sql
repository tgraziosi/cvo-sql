SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_part_sp]	
	@validating_part_no_field char(1),
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

DECLARE @line_count 		int,
	@is_custom_kit 		char(1),
	@vendor_sn		char(1),
	@tdc_generated 		bit,	
	@io_count		int,
	@lb_tracking		char(1),	
	@packing_flg		int,
	@ret			int,
	@orig_part_no		varchar(30),

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


	IF (LTRIM(RTRIM(@part_no)) = '')
	BEGIN
		SELECT @err_msg = 'You must enter a part number'
		RETURN -1
	END	

	--####################################################################################	
	--Check for shortcut keys
	--####################################################################################	
	IF (LEFT(LTRIM(@part_no), 1) = '#')
	BEGIN
		SELECT @line_no = CAST(RIGHT(LTRIM(@part_no),LEN(LTRIM(@part_no)) -1) AS INT)
		
		IF EXISTS(SELECT * 
			    FROM ord_list(NOLOCK)
			   WHERE order_no = @order_no
			     AND order_ext = @order_ext
			     AND line_no = @line_no)
		BEGIN
			SELECT @part_no = part_no 
			  FROM ord_list(NOLOCK)
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext 
			   AND line_no  = @line_no
		END
		ELSE
		BEGIN
			SELECT @err_msg = 'Invalid line number'
			RETURN -1
		END
	END
	ELSE
	--------------------------------------------------------------------------------------	
	-- Not using shortcut keys
	--------------------------------------------------------------------------------------	
	BEGIN
 
		-- UPC Logic
		SELECT @orig_part_no = @part_no

		IF (@validating_part_no_field = 'Y')
		BEGIN
			IF ISNULL((SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'upc_only'), 'N') = 'Y'
			BEGIN
				EXEC tdc_get_part_from_uom_sp @part_no output, @uom output
			END
			ELSE
			BEGIN
				IF NOT EXISTS(SELECT * FROM ord_list(NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no)
					EXEC tdc_get_part_from_uom_sp @part_no output, @uom output
			END
		END


		IF NOT EXISTS(SELECT * 
				FROM inventory (NOLOCK)
			       WHERE part_no = @part_no)
		BEGIN
			SELECT @err_msg = 'Invalid Part Number'
			RETURN -4
		END
		IF NOT EXISTS(SELECT * 
				FROM inventory a (NOLOCK),
				     ord_list  b (NOLOCK)
			       WHERE a.part_no   = @part_no
				 AND b.order_no  = @order_no
				 AND b.order_ext = @order_ext
				 AND b.part_no   = a.part_no)
		BEGIN
			SELECT @err_msg = 'Invalid Part Number for order: '
			RETURN -5
		END
		IF ISNULL(@line_no, 0) = 0
		BEGIN
			--Get the line number
			SELECT @line_count = COUNT(*) 
			  FROM ord_list  (NOLOCK)
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext
			   AND part_no   = @part_no
	
			IF (@line_count = 1)  
			BEGIN
				SELECT @line_no  = line_no 
				  FROM ord_list (NOLOCK)
				 WHERE order_no  = @order_no
				   AND order_ext = @order_ext
				   AND part_no   = @part_no
			END
			ELSE
			BEGIN
				SELECT @part_no = @orig_part_no 
				RETURN @ID_LINE_NO
			END
		END
	END
	--------------------------------------------------------------------------------------	
	--First Do validation
	--------------------------------------------------------------------------------------	
	IF @tran_id > 0
	BEGIN
 	
		IF NOT EXISTS(SELECT * FROM tdc_pick_queue(NOLOCK) WHERE tran_id = @tran_id AND part_no = @part_no)
		BEGIN
			IF NOT EXISTS(	SELECT status FROM inv_master (NOLOCK) WHERE part_no = @part_no AND status = 'C')
			BEGIN
				SELECT @err_msg = 'Invalid part for queue tran id'
				RETURN -6
			END
		END
	END
	
	--Determine if part is a custom kit 
	IF EXISTS(SELECT * FROM ord_list (NOLOCK) 
		   WHERE order_no  = @order_no
                     AND order_ext = @order_ext
                     AND part_type = 'C' 
                     AND part_no   = @part_no)
        
		SELECT @is_custom_kit = 'Y' 
	ELSE	
		SELECT @is_custom_kit = 'N'
 
	--Fill the location value
	SELECT @location = location 
	  FROM ord_list (NOLOCK)
	 WHERE order_no  = @order_no
	   AND order_ext = @order_ext
	   AND line_no   = @line_no		
 
	--If not in pick/pack mode, make sure that the part has been picked
	IF @is_packing = 'Y'
	BEGIN
		IF @is_3_step = 'N'
		BEGIN
			IF @is_custom_kit = 'N'
			BEGIN
				IF NOT EXISTS(SELECT * 
						FROM tdc_dist_item_pick (NOLOCK)
					       WHERE order_no   = @order_no
						 AND order_ext  = @order_ext
						 AND line_no    = @line_no
						 AND part_no    = @part_no
					 	 AND [function] = 'S'
						 AND quantity > 0)
					AND @line_count = 1
		
				BEGIN
					SELECT @err_msg = 'Item has not been picked'
					RETURN -8
				END
			END
			ELSE
			BEGIN
				IF NOT EXISTS(SELECT * FROM tdc_ord_list_kit a(NOLOCK)
					   WHERE a.order_no   = @order_no
					     AND a.order_ext  = @order_ext
					     AND a.part_no    = @part_no
					     AND a.line_no    = @line_no
					     AND a.kit_picked > ISNULL((SELECT SUM(b.pack_qty)
								    FROM tdc_carton_detail_tx b(NOLOCK)
							           WHERE b.order_no = a.order_no
								     AND b.order_ext = a.order_ext
								     AND b.line_no   = a.line_no
								     AND b.part_no   = a.kit_part_no),0))	
				BEGIN
					SELECT @err_msg = 'Not all components have been picked'
					RETURN -9
				END
			END
		END
		ELSE -- 3 step
		BEGIN
			IF NOT EXISTS(SELECT * from ord_list(NOLOCK) 
					WHERE order_no = @order_no 
					 AND order_ext = @order_ext 
					 AND line_no = @line_no 
					 AND part_type = 'V')
			BEGIN
				IF @is_custom_kit = 'N' 
				BEGIN
					IF NOT EXISTS(SELECT * FROM tdc_pick_queue  (NOLOCK)
						       WHERE trans = 'STDPICK'
							 AND CAST(trans_type_no AS INT) = @order_no
							 AND CAST(trans_type_ext AS INT) = @order_ext
							 AND tx_lock = '3'
							 AND part_no = @part_no)
					BEGIN
						SELECT @err_msg = 'Invalid part'
						RETURN -10
					END
				END
				ELSE IF @is_custom_kit = 'Y' 
				BEGIN
					IF NOT EXISTS(SELECT * FROM tdc_pick_queue  (NOLOCK)
						       WHERE trans = 'STDPICK'
							 AND CAST(trans_type_no AS INT) = @order_no
							 AND CAST(trans_type_ext AS INT) = @order_ext
							 AND tx_lock = '3'
							 AND part_no IN(SELECT b.part_no 
									  FROM ord_list     a (NOLOCK), 
									       ord_list_kit b (NOLOCK)	
									 WHERE a.order_no = @order_no
									   AND a.order_ext = @order_ext
									   AND a.part_no = @part_no
									   AND a.order_no = b.order_no
									   AND a.order_ext = b.order_ext
									   AND a.line_no = b.line_no))
					BEGIN
						SELECT @err_msg = 'Invalid custom kit for queue tran id'
						RETURN -11
					END
				END
			END
		END

		--If packing from tote bins, verify that the part is in the tote
		IF @tote_bin <> '' 
		BEGIN				
			IF (@is_custom_kit = 'N')
			BEGIN
				IF NOT EXISTS(SELECT * FROM tdc_tote_bin_tbl (NOLOCK)
					       WHERE order_no   = @order_no
						 AND order_ext  = @order_ext
						 AND part_no    = @part_no
						 AND line_no    = @line_no
						 AND location   = @location
						 AND bin_no     = @tote_bin
						 AND order_type = 'S')
				BEGIN
					SELECT @err_msg = 'Item not found in the tote bin'
					RETURN -12
				END
			END
			ELSE --Is kit item
			BEGIN
				IF NOT EXISTS (SELECT * 
						 FROM tdc_tote_bin_tbl a(NOLOCK),
						      ord_list_kit     b(NOLOCK)   
						WHERE a.order_no   = @order_no
						  AND a.order_ext  = @order_ext
						  AND a.line_no    = @line_no
						  AND a.location   = @location
						  AND a.bin_no     = @tote_bin
						  AND a.order_type = 'S'
						  AND b.order_no   = a.order_no
						  AND b.order_ext  = a.order_ext
						  AND b.location   = a.location
						  AND b.line_no    = a.line_no
						  AND b.part_no    = a.part_no)
				BEGIN
					SELECT @err_msg = 'Components of custom kit not found in the tote bin'
					RETURN -13
				END
			END		
		END
	END
	ELSE IF @is_packing = 'N'
	BEGIN
		IF (@is_custom_kit = 'N')
		BEGIN
			IF NOT EXISTS(SELECT *
					FROM tdc_carton_detail_tx (NOLOCK)
				       WHERE carton_no = @carton_no
					 AND part_no   = @part_no)
			BEGIN
				SELECT @err_msg = 'Item has not been packed'
				RETURN -14
			END
		END
	END
	
	--------------------------------------------------------------------------------------	
	--Determine which field to set focus to 
	--------------------------------------------------------------------------------------	

	--If custom kits in order, set focus to kits field
	IF @is_custom_kit = 'Y' 
		RETURN @ID_KIT_ITEM
 
	-- If the UOM has not been filled by the UPC logic, fill it.
	IF ISNULL(@uom, '') = ''
	BEGIN
		SELECT @uom = uom	
		  FROM ord_list(NOLOCK) 
		WHERE order_no = @order_no
		 AND order_ext = @order_ext
		 AND line_no = @line_no
	END
 
	SELECT @vendor_sn = vendor_sn 
	  FROM tdc_inv_list (nolock)
	 WHERE part_no  = @part_no
   	   AND location = @location
		 
	SELECT @tdc_generated = tdc_generated 
	  FROM tdc_inv_master (nolock)   
	 WHERE part_no = @part_no

	SET @io_count = 0

	IF @is_packing = 'Y'
		SET @io_count = 1

	--if lot/bin tracked then 
	SELECT @lb_tracking = lb_tracking
	  FROM inv_master (NOLOCK)
	 WHERE part_no = @part_no	

	--Serialized parts
	IF((@vendor_sn = 'O' AND @tdc_generated = 0)
	OR (@vendor_sn = 'I'))
	BEGIN
		IF @is_packing = 'Y'
		BEGIN
			IF((@is_3_step = 'Y' AND @lb_tracking = 'Y' AND ISNULL(@tran_id, 0) > 0)
			OR (@is_3_step = 'Y' AND @lb_tracking = 'N')
			OR (@vendor_sn = 'I')
			OR (@vendor_sn = 'O' AND @auto_lot <> ''))
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

	IF EXISTS(SELECT * FROM tdc_inv_list (NOLOCK) WHERE location = @location AND part_no = @part_no AND ISNULL(version_capture, 0) != 0)
	AND @is_packing = 'Y'
		RETURN @ID_VERSION
	ELSE
		RETURN @ID_QUANTITY

 
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_part_sp] TO [public]
GO
