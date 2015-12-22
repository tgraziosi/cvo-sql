SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_serial_lot_range_sp]
	@is_packing 	char(1),	
	@carton_no 	int,
	@order_no 	int,
	@order_ext 	int,
	@line_no 	int,
	@part_no 	varchar(30),		
	@lot_ser	varchar(25),
	@err_msg 	varchar(255) OUTPUT 

AS 

DECLARE @vendor_sn 		char(1),
	@serial_no_masked 	varchar(40),
	@ret			int,
	@location		varchar(10),
	@is_3_step 		char(1),
 
--FIELD INDEXES TO BE RETURNED TO VB
	@ID_SERIAL_VERSION	int 


	IF EXISTS(SELECT * 
		    FROM tdc_cons_ords (NOLOCK)
		   WHERE order_no = @order_no
		     AND order_ext = @order_ext
	 	     AND alloc_type = 'PP')
	BEGIN
		SELECT @is_3_step = 'Y'
	END
	ELSE
		SELECT @is_3_step = 'N'


	SELECT @location = location 
	  FROM ord_list (NOLOCK)
	 WHERE order_no= @ordeR_no
	   AND order_ext = @order_ext
	   AND line_no=  @line_no
	----------------------------------------------------------------------------------------------------------------------------
	--Set the values of the field indexes
	----------------------------------------------------------------------------------------------------------------------------
	SELECT @ID_SERIAL_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
		WHERE order_type = 'S' AND field_name = 'SERIAL_VERSION'
 
	---------------------------------------------------------------------------------------------------
	-- Make sure the lot is entered
	---------------------------------------------------------------------------------------------------
	IF ISNULL(@lot_ser, '') = ''
	BEGIN
		SELECT @err_msg = 'Lot/Ser is required'
		RETURN -1
	END

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
                        		 AND last_control_type <> 'Q'  
                       			 AND last_trans <> 'STDXPICK'  
                          		 AND last_trans <> 'STDXSHVF')
			BEGIN
				SELECT @err_msg = 'Invalid lot/ser'
				RETURN -3
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
					 AND lot_ser = @lot_ser)
			BEGIN
				SELECT @err_msg = 'Serial number with this lot/ser is not in carton'
				RETURN -5
			END
		END
	END
	ELSE --Packing
	BEGIN

		IF (@vendor_sn = 'I')
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	       WHERE part_no = @part_no
					 AND lot_ser = @lot_ser
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
				SELECT @err_msg = 'Invalid lot/ser'
				RETURN -7
			END


			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	   WHERE part_no = @part_no
				     AND lot_ser = @lot_ser
                        	     AND last_control_type <> 'Q'  
                       		     AND last_trans <> 'STDXPICK'  
                          	     AND last_trans <> 'STDXSHVF' 
			 	     AND io_count % 2 != 0 )
			BEGIN
				SELECT @err_msg = 'Serial number with this lot/ser not in inventory'
				RETURN -8
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
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_serial_lot_range_sp] TO [public]
GO
