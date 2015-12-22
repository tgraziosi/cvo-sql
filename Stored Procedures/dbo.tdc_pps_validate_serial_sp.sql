SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_serial_sp]
	@is_packing 	char(1),
	@is_3_step 	char(1),
	@tote_bin	varchar(12),
	@carton_no 	int,
	@order_no 	int,
	@order_ext 	int,
	@line_no 	int,
	@part_no 	varchar(30),	
	@kit_item	varchar(30),
	@location 	varchar(10),
	@serial_no 	varchar(40),
	@lot_ser	varchar(25) OUTPUT,
	@bin_no		varchar(12) OUTPUT,
	@err_msg 	varchar(255) OUTPUT,
	@tran_id	int = -1  --OPTIONAL PARAMETER
 
AS 
 
DECLARE @vendor_sn 		char(1),
	@serial_no_masked 	varchar(40),
	@ret			int,
	@packing_flg		int,
	@part			varchar(30),
 
--FIELD INDEXES TO BE RETURNED TO VB
	@ID_AUTO_SCAN_QTY	int,
	@ID_SERIAL_VERSION	int,
	@ID_SERIAL_LOT		int
 	
	----------------------------------------------------------------------------------------------------------------------------
	--Set the values of the field indexes
	----------------------------------------------------------------------------------------------------------------------------
	SELECT @ID_AUTO_SCAN_QTY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'AUTO_SCAN_QTY'

	SELECT @ID_SERIAL_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'SERIAL_VERSION'

	SELECT @ID_SERIAL_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'SERIAL_LOT'
 
	
	---------------------------------------------------------------------------------------------------
	-- Make sure the serial is entered
	---------------------------------------------------------------------------------------------------
	IF ISNULL(@serial_no, '') = ''
	BEGIN
		SELECT @err_msg = 'Serial is required'
		RETURN -1
	END

	IF ISNULL(@kit_item, '') = ''
		SELECT @part = @part_no
	ELSE
		SELECT @part = @kit_item

	---------------------------------------------------------------------------------------------------
	-- Mask the serial no
	---------------------------------------------------------------------------------------------------
	EXEC @ret = tdc_format_serial_mask_sp @part, @serial_no, @serial_no_masked OUTPUT, @err_msg OUTPUT
	IF @ret <> 1 RETURN -2

	---------------------------------------------------------------------------------------------------
	-- Get the Vendor SN flag
	---------------------------------------------------------------------------------------------------
	SELECT @vendor_sn = vendor_sn FROM tdc_inv_list (NOLOCK)
		WHERE location = @location
		AND part_no = @part
 
 
	--NOTE: If I/O count is even, then part is out of stock

	---------------------------------------------------------------------------------------------------
	-- Unpacking
	---------------------------------------------------------------------------------------------------
	IF (@is_packing = 'N')
	BEGIN
		IF @vendor_sn = 'I'
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	       WHERE part_no = @part
                           		 AND serial_no_raw = @serial_no
					 AND (@lot_ser = '' OR lot_ser = @lot_ser)
                        		 AND last_control_type <> 'Q'  
                       			 AND last_trans <> 'STDXPICK'  
                          		 AND last_trans <> 'STDXSHVF')
			BEGIN
				SELECT @err_msg = 'Invalid serial no'
				RETURN -3
			END
			IF NOT EXISTS(SELECT null FROM tdc_serial_no_track (NOLOCK)  
                           		WHERE part_no =  @part
                           		AND serial_no_raw =  @serial_no
                        		AND last_control_type <> 'Q'
					 AND (@lot_ser = '' OR lot_ser = @lot_ser)  
                       			AND last_trans <> 'STDXPICK'  
                          		AND last_trans <> 'STDXSHVF' 
			 		AND io_count % 2 = 0 )
			BEGIN
				SELECT @err_msg = 'Serial number already in inventory'
				RETURN -4
			END
		END
		IF (@vendor_sn = 'O' OR @vendor_sn = 'I')
		BEGIN
			IF NOT EXISTS(SELECT * 
					FROM tdc_carton_detail_tx a(NOLOCK),
					     tdc_carton_tx b(NOLOCK)	
                       		       WHERE a.carton_no = @carton_no
					 AND a.order_no = @order_no
					 AND a.order_ext = @order_ext
					 AND (@lot_ser = '' OR lot_ser = @lot_ser)
					 AND a.carton_no = b.carton_no
					 AND b.order_type = 'S'
					 AND a.part_no = @part
                           		 AND a.serial_no_raw = @serial_no)
			BEGIN
				SELECT @err_msg = 'Serial number is not in carton'
				RETURN -5
			END
		END

		IF ISNULL((SELECT COUNT(lot_ser)
			FROM tdc_carton_detail_tx a(NOLOCK),
			     tdc_carton_tx b(NOLOCK)	
			       WHERE a.carton_no = @carton_no
			 AND a.order_no = @order_no
			 AND a.order_ext = @order_ext
			 AND a.carton_no = b.carton_no
			 AND b.order_type = 'S'
			 AND a.part_no = @part
	   		 AND a.serial_no_raw = @serial_no), 0) > 1
		BEGIN
			RETURN @ID_SERIAL_LOT
		END
		ELSE
			SELECT @lot_ser = lot_ser
			FROM tdc_carton_detail_tx a(NOLOCK),
			     tdc_carton_tx b(NOLOCK)	
			       WHERE a.carton_no = @carton_no
			 AND a.order_no = @order_no
			 AND a.order_ext = @order_ext
			 AND a.carton_no = b.carton_no
			 AND b.order_type = 'S'
			 AND a.part_no = @part
	   		 AND a.serial_no_raw = @serial_no
	END
	ELSE --Packing
	BEGIN
              	IF EXISTS(SELECT * 
			    FROM tdc_carton_detail_tx a(NOLOCK),
				 tdc_carton_tx b(NOLOCK)
              		   WHERE a.order_no = @order_no
			     AND a.order_ext = @order_ext
			     AND a.carton_no = b.carton_no
			     AND (@lot_ser = '' OR lot_ser = @lot_ser)
			     AND b.order_type = 'S'
                    	     AND a.part_no = @part
                    	     AND a.serial_no_raw = @serial_no)
		BEGIN
			SELECT @err_msg = 'Serial number already packed'
			RETURN -6
		END

		IF (@vendor_sn = 'I')
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	       WHERE part_no = @part
                           	         AND serial_no_raw = @serial_no
                        		 AND last_control_type <> 'Q'
					 AND (@lot_ser = '' OR lot_ser = @lot_ser)  
                       			 AND last_trans <> 'STDXPICK'  
                          		 AND last_trans <> 'STDXSHVF'
					 AND lot_ser IN (SELECT lot_ser
							   FROM tdc_dist_item_pick(NOLOCK)
							  WHERE order_no = @order_no
							    AND order_ext = @order_ext
					 		    AND (@lot_ser = '' OR lot_ser = @lot_ser)
							    AND line_no = @line_no
							    AND [function] = 'S'
							  UNION 
							 SELECT lot_ser
							   FROM lot_bin_ship(NOLOCK)
							  WHERE tran_no = @order_no
							    AND tran_ext = @order_ext
					 		    AND (@lot_ser = '' OR lot_ser = @lot_ser)
							    AND line_No = @line_no
							    AND part_no = @part)) AND @is_3_step = 'N'
			BEGIN
				SELECT @err_msg = 'Invalid serial number'
				RETURN -7
			END
 
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	       WHERE part_no = @part
					 AND (@lot_ser = '' OR lot_ser = @lot_ser)
                           	         AND serial_no_raw = @serial_no
                        	         AND last_control_type <> 'Q'  
                       		         AND last_trans <> 'STDXPICK'  
                          	         AND last_trans <> 'STDXSHVF' 
			 	         AND io_count % 2 != 0 )
			BEGIN
				SELECT @err_msg = 'Serial number not in inventory'
				RETURN -8
			END

		END

		IF (@vendor_sn = 'O')
		BEGIN
                     	IF EXISTS(SELECT * FROM tdc_serial_no_track a(NOLOCK) 
                      		WHERE part_no = @part
                            	  AND serial_no_raw = @serial_no)
			BEGIN
				SELECT @err_msg = 'Duplicate serial number: ' + @serial_no
				RETURN -9
			END
		END
 
		---------------------------------------------------------------------------------------------------
		-- Determine where to go next
		---------------------------------------------------------------------------------------------------
		IF (SELECT COUNT(lot_ser) 
		      FROM tdc_serial_no_track(NOLOCK)
		     WHERE location = @location
		       AND part_no = @part
		       AND serial_no_raw = @serial_no
		       AND last_control_type <> 'Q'  
	 	       AND last_trans <> 'STDXPICK'  
	  	       AND last_trans <> 'STDXSHVF'
		       AND lot_ser IN (SELECT lot_ser
					 FROM tdc_dist_item_pick(NOLOCK)
					WHERE order_no = @order_no
					  AND order_ext = @order_ext
					  AND line_no = @line_no
					  AND [function] = 'S'
					UNION 
				       SELECT lot_ser
					 FROM lot_bin_ship(NOLOCK)
					WHERE tran_no = @order_no
					  AND tran_ext = @order_ext
					  AND line_No = @line_no
					  AND part_no = @part)) > 1
		BEGIN
			RETURN @ID_SERIAL_LOT
		END
		ELSE
		BEGIN
			IF @is_3_step = 'N'
			BEGIN
				SELECT @lot_ser = lot_ser
				  FROM tdc_serial_no_track (NOLOCK)
				 WHERE location = @location
				   AND part_no = @part
				   AND serial_no_raw = @serial_no
			           AND lot_ser IN (SELECT lot_ser
						 FROM tdc_dist_item_pick(NOLOCK)
						WHERE order_no = @order_no
						  AND order_ext = @order_ext
						  AND line_no = @line_no
						  AND [function] = 'S'
						UNION 
					       SELECT lot_ser
						 FROM lot_bin_ship(NOLOCK)
						WHERE tran_no = @order_no
						  AND tran_ext = @order_ext
						  AND line_No = @line_no
						  AND part_no = @part) 
			END
			ELSE
			BEGIN
				SELECT @lot_ser = lot_ser
				  FROM tdc_serial_no_track (NOLOCK)
				 WHERE location = @location
				   AND part_no = @part
				   AND serial_no_raw = @serial_no 
			END
		END
 	END

	IF @is_packing = 'Y'
		SELECT @packing_flg = 1
	ELSE
		SELECT @packing_flg = 0

	EXEC tdc_pps_get_bin_sp @is_packing, @carton_no, @tote_bin, @order_no, @order_ext, @line_no, @part, @kit_item, @location, @lot_ser, @bin_no OUTPUT, @tran_id

	IF ISNULL(@bin_no, '') = ''
	BEGIN
		SELECT TOP 1 @bin_no = bin_no 
		  FROM tdc_pick_queue(NOLOCK)
	         WHERE trans = 'STDPICK'
		   AND CAST(trans_type_no AS INT) = @order_no
		   AND CAST(trans_type_ext AS INT) = @order_ext
		   AND tx_lock = '3'
		   AND part_no = @part_no
		   AND lot = @lot_ser
	
	END

	IF EXISTS(SELECT * 
		    FROM tdc_inv_list  (NOLOCK)
		   WHERE part_no = @part
		     AND location = @location
		     AND version_capture = 1) AND @is_packing = 'Y'
		RETURN @ID_SERIAL_VERSION
	ELSE
		RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_serial_sp] TO [public]
GO
