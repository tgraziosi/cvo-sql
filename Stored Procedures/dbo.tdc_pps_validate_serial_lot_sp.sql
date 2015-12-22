SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_serial_lot_sp]
	@is_packing 	char(1),
	@is_3_step 	char(1),
	@carton_no 	int,
	@order_no 	int,
	@order_ext 	int,
	@line_no 	int,
	@part_no 	varchar(30),	
	@location 	varchar(10),
	@serial_no 	varchar(40),
	@lot_ser	varchar(25),
	@err_msg 	varchar(255) OUTPUT 

AS 

DECLARE @vendor_sn 		char(1),
	@serial_no_masked 	varchar(40),
	@ret			int,
 
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
	-- Make sure the lot is entered
	---------------------------------------------------------------------------------------------------
	IF ISNULL(@lot_ser, '') = ''
	BEGIN
		SELECT @err_msg = 'Lot/Ser is required'
		RETURN -1
	END

	---------------------------------------------------------------------------------------------------
	-- Mask the serial no
	---------------------------------------------------------------------------------------------------
	EXEC @ret = tdc_format_serial_mask_sp @part_no, @serial_no, @serial_no_masked OUTPUT, @err_msg OUTPUT
	IF @ret <> 1 RETURN -2

	---------------------------------------------------------------------------------------------------
	-- Get the Vendor SN flag
	---------------------------------------------------------------------------------------------------
	SELECT @vendor_sn = vendor_sn FROM tdc_inv_list (NOLOCK)
		WHERE location = @location
		AND part_no = @part_no

	--NOTE: If I/O count is even, then part is out of stock

	---------------------------------------------------------------------------------------------------
	-- Unpacking
	---------------------------------------------------------------------------------------------------
	IF (@is_packing = 'N')
	BEGIN
		IF @vendor_sn = 'I'
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	       WHERE part_no = @part_no
					 AND lot_ser = @lot_ser
                           		 AND serial_no_raw = @serial_no
                        		 AND last_control_type <> 'Q'  
                       			 AND last_trans <> 'STDXPICK'  
                          		 AND last_trans <> 'STDXSHVF')
			BEGIN
				SELECT @err_msg = 'Invalid lot/ser'
				RETURN -3
			END
			IF EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           		WHERE part_no = @part_no
					  AND lot_ser = @lot_ser
                           		  AND serial_no_raw = @serial_no
                        		  AND last_control_type <> 'Q'  
                       			  AND last_trans <> 'STDXPICK'  
                          		  AND last_trans <> 'STDXSHVF' 
			 		  AND io_count % 2 > 0 )
			BEGIN
				SELECT @err_msg = 'Serial / lot already in inventory'
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
					 AND a.carton_no = b.carton_no
					 AND b.order_type = 'S'
					 AND a.part_no = @part_no
					 AND lot_ser = @lot_ser
                           		 AND a.serial_no_raw = @serial_no)
			BEGIN
				SELECT @err_msg = 'Serial / lot is not in carton'
				RETURN -5
			END
		END
	END
	ELSE --Packing
	BEGIN
              	IF EXISTS(SELECT * 
			    FROM tdc_carton_detail_tx a(NOLOCK),
				 tdc_carton_tx b(NOLOCK)
              		   WHERE a.order_no = @order_no
			     AND a.order_ext = @order_ext
			     AND a.carton_no = b.carton_no
			     AND b.order_type = 'S'
                    	     AND a.part_no = @part_no
			     AND lot_ser = @lot_ser
                    	     AND a.serial_no_raw = @serial_no)
		BEGIN
			SELECT @err_msg = 'Serial number / lot already packed'
			RETURN -6
		END

		IF (@vendor_sn = 'I')
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	       WHERE part_no = @part_no
					 AND lot_ser = @lot_ser
                           	         AND serial_no_raw = @serial_no
                        		 AND last_control_type <> 'Q'  
                       			 AND last_trans <> 'STDXPICK'  
                          		 AND last_trans <> 'STDXSHVF'
					 AND lot_ser IN (SELECT lot_ser
							   FROM tdc_dist_item_pick(NOLOCK)
							  WHERE order_no = @order_no
							    AND order_ext = @order_ext
							    AND line_no = @line_no
					 		    AND lot_ser = @lot_ser
							    AND [function] = 'S'
							  UNION 
							 SELECT lot_ser
							   FROM lot_bin_ship(NOLOCK)
							  WHERE tran_no = @order_no
							    AND tran_ext = @order_ext
							    AND line_No = @line_no
							    AND part_no = @part_no
					 		    AND lot_ser = @lot_ser))
			BEGIN
				SELECT @err_msg = 'Invalid serial / lot'
				RETURN -7
			END


			IF EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	   WHERE part_no = @part_no
				     AND lot_ser = @lot_ser
                           	     AND serial_no_raw = @serial_no
                        	     AND last_control_type <> 'Q'  
                       		     AND last_trans <> 'STDXPICK'  
                          	     AND last_trans <> 'STDXSHVF' 
			 	     AND io_count % 2 = 0 )
			BEGIN
				SELECT @err_msg = 'Serial / lot not in inventory'
				RETURN -8
			END

		END

		IF (@vendor_sn = 'O')
		BEGIN
                     	IF EXISTS(SELECT * FROM tdc_serial_no_track a(NOLOCK) 
                      		WHERE part_no = @part_no
				  AND lot_ser = @lot_ser
                            	  AND serial_no_raw = @serial_no)
			BEGIN
				SELECT @err_msg = 'Duplicate serial / lot: ' + @serial_no
				RETURN -9
			END
		END

	END
 
	---------------------------------------------------------------------------------------------------
	-- Determine where to go next
	---------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT * 
		    FROM tdc_inv_list  (NOLOCK)
		   WHERE part_no = @part_no
		     AND location = @location
		     AND ISNULL(version_capture, 0) = 1) AND @is_packing = 'Y'
		RETURN @ID_SERIAL_VERSION
	ELSE
		RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_serial_lot_sp] TO [public]
GO
