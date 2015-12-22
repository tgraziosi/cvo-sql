SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_lot_sp]	
	@is_packing	char(1),
	@is_3_step	char(1),
	@carton_no	int,
	@tote_bin	varchar(12),
	@order_no	int,
	@order_ext	int,
	@auto_bin	varchar(25),
	@part_no	varchar(30)    OUTPUT,
	@kit_item	varchar(30)    OUTPUT,
	@line_no	int	       OUTPUT,		
	@location	varchar(10)    OUTPUT,	
	@lot_ser	varchar(25)    OUTPUT,
	@bin_no		varchar(12)    OUTPUT,
	@qty		decimal(20, 8) OUTPUT,
	@err_msg	varchar(255)   OUTPUT

AS	

DECLARE @Part			varchar(30),	
	@ret			int,
	@vendor_sn 		char(1),
	@tdc_generated		bit,
	@packing_flg		int,
	@lb_tracking 		char(1),
	--FIELD INDEXES TO BE RETURNED TO VB
	@ID_BIN		 	int,
	@ID_VERSION		int,
	@ID_QUANTITY		int,
	@ID_LINE_NO		int,
	@ID_SCAN_SERIAL		int,	
 	@ID_AUTO_SCAN_QTY	int

----------------------------------------------------------------------------------------------------------------------------
--Set the values of the field indexes
----------------------------------------------------------------------------------------------------------------------------
SELECT @ID_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'BIN'

SELECT @ID_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'VERSION'

SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'QTY'

SELECT @ID_AUTO_SCAN_QTY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'AUTO_SCAN_QTY'

SELECT @ID_LINE_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'LINE_NO'

SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'SCAN_SERIAL'
 

SELECT @vendor_sn = 'N'
 

	IF (LTRIM(RTRIM(@lot_ser)) = '')
	BEGIN
		SELECT @err_msg = 'You must enter a lot'
		RETURN -1
	END

	--get part to be processed
	--If it is kit, set part = kititem
	IF (@kit_item <> '')  
		SELECT @Part = @kit_item
	ELSE
		SELECT @Part = @part_no
			
	IF @is_packing = 'N' --Unpacking
	BEGIN
		IF NOT EXISTS(SELECT *
				FROM tdc_carton_detail_tx a(NOLOCK),
				     tdc_carton_tx b(NOLOCK) 
     			       WHERE a.line_no    = @line_no
     				 AND a.lot_ser    = @lot_ser
     				 AND a.order_no   = @order_no
     				 AND a.order_ext  = @order_ext
				 AND a.carton_no  = b.carton_no
				 AND b.order_type = 'S')
		BEGIN
			SELECT @err_msg = 'Invalid Lot'
			RETURN -2
		END
	END  
	ELSE IF @is_packing = 'Y'  -- packing 
	BEGIN
		IF @is_3_step = 'N'
		BEGIN
			IF (@kit_item <> '')  --Kit Item
			BEGIN
	    			IF NOT EXISTS(SELECT lot_ser , sum(qty)
						FROM tdc_ord_list_kit a (NOLOCK), 
						     lot_bin_ship     b(NOLOCK)  
					       WHERE a.order_no     = @order_no
						 AND a.order_ext    = @order_ext
						 AND a.order_no     = b.tran_no  
						 AND a.order_ext    = b.tran_ext   
						 AND a.line_no      = b.line_no   
						 AND b.lot_ser      = @lot_ser
						 AND (a.kit_part_no = @Part OR a.sub_kit_part_no = @Part) 
					       GROUP BY order_no, order_ext, lot_ser
					      HAVING SUM(qty) > ISNULL((SELECT SUM(pack_qty) 
								         FROM tdc_carton_detail_tx c(NOLOCK)
								        WHERE c.order_no = @order_no
								          AND c.order_ext = @order_ext
								          AND c.part_no = @part
								          AND c.lot_ser = @lot_ser), 0))

				BEGIN
					SELECT @err_msg = 'Invalid Lot'
					RETURN -3
				END	
			END
			ELSE --Not Kit Item
			BEGIN
	    			IF NOT EXISTS(SELECT *
						FROM tdc_dist_item_pick (NOLOCK)  
	         			       WHERE order_no   = @order_no
		         			 AND order_ext  = @order_ext
		         			 AND line_no    = @line_no
		         			 AND lot_ser    = @lot_ser
		         			 AND part_no	= @Part
						 AND [function] = 'S')
	
				BEGIN
					SELECT @err_msg = 'Invalid Lot'
					RETURN -4
				END	
			END --Not Kit Item
		END
		ELSE -- 3 STEP
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) 
				       WHERE trans = 'STDPICK'
					 AND CAST(trans_type_no AS INT) = @order_no
					 AND CAST(trans_type_ext AS INT) = @order_ext
					 AND tx_lock = '3'
					 AND part_no = @part
					 AND lot = @lot_ser)
			BEGIN
				SELECT @err_msg = 'Invalid lot'
				RETURN -5
			END
		END


		IF @tote_bin != ''
		BEGIN
			IF (@kit_item <> '')  --Kit Item
				IF NOT EXISTS(SELECT * FROM tdc_tote_bin_tbl (NOLOCK)
					       WHERE bin_no    = @tote_bin
						 AND order_no  = @order_no
						 AND order_ext = @order_ext
						 AND line_no   = @line_no
						 AND part_no   = @kit_item
						 AND lot_ser   = @lot_ser)
				BEGIN
					SELECT @err_msg = 'Invalid Lot for tote bin'
					RETURN -6
				END
			ELSE
			BEGIN
				IF NOT EXISTS(SELECT * FROM tdc_tote_bin_tbl (NOLOCK)
					       WHERE bin_no    = @tote_bin
						 AND order_no  = @order_no
						 AND order_ext = @order_ext
						 AND line_no   = @line_no
						 AND part_no   = @part_no
						 AND lot_ser   = @lot_ser)
				BEGIN
					SELECT @err_msg = 'Invalid Lot for tote bin'
					RETURN -7
				END
			END
		END
	END--Not Pickpack

	--If epicor serialized part, the lot is the serial number; pack the item.
	IF EXISTS(SELECT * 
		    FROM inv_master (NOLOCK) 
	           WHERE part_no = @part
		     AND lb_tracking = 'Y' 
		     AND serial_flag = 1) 
	BEGIN	
		IF @is_packing = 'Y'
		BEGIN
			IF @is_3_step = 'N'
			BEGIN
				SELECT @bin_no = bin_no
				  FROM lot_bin_ship (NOLOCK)
				 WHERE tran_no   = @order_no
				   AND tran_ext  = @order_ext
				   AND line_no   = @line_no
				   AND part_no   = @part
				   AND lot_ser   = @lot_ser			

			END
			ELSE
			BEGIN
				SELECT @bin_no = bin_no
				  FROM tdc_pick_queue (NOLOCK) 
			         WHERE trans = 'STDPICK'
				   AND CAST(trans_type_no AS INT) = @order_no
				   AND CAST(trans_type_ext AS INT) = @order_ext
				   AND tx_lock = '3'
				   AND part_no = @part
				   AND lot = @lot_ser 

			END
		 
			IF EXISTS(SELECT * FROM tdc_inv_list (NOLOCK) WHERE location = @location AND part_no = @part AND ISNULL(version_capture, 0) != 0)
			AND @is_packing = 'Y'
				RETURN @ID_VERSION
			ELSE
			BEGIN
				SELECT @qty = 1
				RETURN @ID_AUTO_SCAN_QTY
			END
		END 
		ELSE --UNPACKING
		BEGIN
			IF @is_3_step = 'N'
			BEGIN
				SELECT @bin_no = bin_no
				  FROM lot_bin_ship (NOLOCK)
				 WHERE tran_no   = @order_no
				   AND tran_ext  = @order_ext
				   AND line_no   = @line_no
				   AND part_no   = @part
				   AND lot_ser   = @lot_ser	

				SELECT @qty = 1
				RETURN @ID_AUTO_SCAN_QTY		
			END
			ELSE
			BEGIN
				RETURN @ID_BIN
			END	
		END
	END

	IF @is_packing = 'Y'
		SELECT @packing_flg = 1
	ELSE
		SELECT @packing_flg = 0


	SELECT @vendor_sn = vendor_sn 
	  FROM tdc_inv_list (NOLOCK)
	 WHERE part_no  = @part
   	   AND location = @location
		 
	SELECT @tdc_generated = tdc_generated 
	  FROM tdc_inv_master (nolock)   
	 WHERE part_no = @part 

	IF((@vendor_sn = 'O' AND @tdc_generated = 0)
	OR (@vendor_sn = 'I'))
	BEGIN
		EXEC tdc_pps_get_bin_sp @is_packing, @carton_no, @tote_bin, @order_no, @order_ext, @line_no, @part_no, @kit_item, @location, @lot_ser, @bin_no OUTPUT 		
		RETURN @ID_SCAN_SERIAL
	END

	IF @is_3_step = 'Y' 
		RETURN @ID_BIN
	ELSE
		IF EXISTS(SELECT * FROM tdc_inv_list (NOLOCK) WHERE location = @location AND part_no = @part AND ISNULL(version_capture, 0) != 0)
		AND @is_packing = 'Y'
			RETURN @ID_VERSION
		ELSE
			RETURN @ID_QUANTITY

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_lot_sp] TO [public]
GO
