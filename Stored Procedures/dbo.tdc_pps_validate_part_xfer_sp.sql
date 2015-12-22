SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pps_validate_part_xfer_sp]
	@validating_part_no_field char(1),
	@packing_flg	int,
	@serial_no_flg	int,
	@tote_bin	varchar(12),
	@xfer_no	int,
	@carton_no 	int,	
	@auto_lot	varchar(25), 
	@auto_bin	varchar(12),

	--input/output
	@line_no        int 	     OUTPUT, 
	@location	varchar(10)  OUTPUT, 	 
	@part_no	varchar(30)  OUTPUT,		
	@serial_no	varchar(40)  OUTPUT, 	
	@uom		varchar(10)  OUTPUT,	
	@lot_ser	varchar(25)  OUTPUT, 	
	@bin_no		varchar(12)  OUTPUT, 
	 	
	--Output only params
	@line_cnt	int 	     OUTPUT,
	@err_msg	varchar(255) OUTPUT 
AS 

DECLARE @cust_code 		varchar(10)
DECLARE @language 		varchar(10)
DECLARE @VerifyPart 		varchar(30)
DECLARE @lb_tracking		char(1)
DECLARE @cnt			int
DECLARE @bPartIsSerialized 	int
DECLARE @vendor_sn 		char(1)
DECLARE	@tdc_generated 		bit

--FIELD INDEXES TO BE RETURNED TO VB
DECLARE @ID_LOT	 	 	int
DECLARE @ID_BIN		 	int
DECLARE @ID_QUANTITY		int
DECLARE @ID_SCAN_SERIAL	 	int
DECLARE @ID_SERIAL_LOT		int

SELECT @vendor_sn = 'N'
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

--Set the values of the field indexes
SELECT @ID_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'LOT'

SELECT @ID_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'BIN'

SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'QUANTITY'

SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SCAN_SERIAL'

SELECT @ID_SERIAL_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SERIAL_LOT'



	SELECT @line_cnt = 1
	SELECT	@bPartIsSerialized = 0

	IF (LTRIM(RTRIM(@part_no)) = '')
	BEGIN
		-- @err_msg = 'You must enter a part number'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_part_xfer_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END

	--####################################################################################	
	--Check for shortcut keys
	--####################################################################################	
	IF (LEFT(LTRIM(@part_no), 1) = '#')
	BEGIN
		SELECT @line_no = CAST(RIGHT(LTRIM(@part_no),LEN(LTRIM(@part_no)) -1) AS INT)
		
		IF EXISTS(SELECT * 
			    FROM xfer_list(NOLOCK)
			   WHERE xfer_no = @xfer_no 
			     AND line_no = @line_no)
		BEGIN
			SELECT @line_no = line_no, 
			       @part_no = part_no 
			  FROM xfer_list(NOLOCK)
			 WHERE xfer_no  = @xfer_no 
			   AND line_no  = @line_no
		END
		ELSE
		BEGIN
			-- @err_msg = 'Invalid line number'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_part_xfer_sp' AND err_no = -103 AND language = @language 
			RETURN -1
		END
	END
	ELSE
	--------------------------------------------------------------------------------------	
	-- Not using shortcut keys
	--------------------------------------------------------------------------------------	
	BEGIN
		-- UPC Logic
		IF (@validating_part_no_field = 'Y')
		BEGIN
			IF ISNULL((SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'upc_only'), 'N') = 'Y'
			BEGIN
				EXEC tdc_get_part_from_uom_sp @part_no output, @uom output
			END
			ELSE
			BEGIN
				IF NOT EXISTS(SELECT * FROM xfer_list(NOLOCK) WHERE xfer_no = @xfer_no AND line_no = @line_no AND part_no = @part_no)
					EXEC tdc_get_part_from_uom_sp @part_no output, @uom output
			END
		END

		IF NOT EXISTS(SELECT * 
				FROM inventory a(NOLOCK)
			       WHERE a.part_no   = @part_no)
		BEGIN
			-- @err_msg = 'Invalid Part Number'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_part_xfer_sp' AND err_no = -104 AND language = @language 
			RETURN -1
		END
		IF NOT EXISTS(SELECT * 
				FROM inventory a(NOLOCK),
				     xfer_list b(NOLOCK)
			       WHERE a.part_no   = @part_no
				 AND b.xfer_no   = @xfer_no
				 AND b.part_no   = a.part_no)
		BEGIN
			-- @err_msg = 'Invalid Part Number for order: '
			SELECT @err_msg = (SELECT err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_part_xfer_sp' AND err_no = -105 AND language = @language) + CAST(@xfer_no AS VARCHAR(255)) 
			RETURN -1
		END

		IF ISNULL(@line_no, 0) = 0
		BEGIN
			--Get the line number
			SELECT @cnt = COUNT(*) 
			  FROM xfer_list (NOLOCK)
			 WHERE xfer_no = @xfer_no
			   AND part_no = @part_no
			IF (@cnt = 1)  
			BEGIN
				SELECT @line_no = line_no 
				  FROM xfer_list (NOLOCK)
				 WHERE xfer_no  = @xfer_no
				   AND part_no  = @part_no
			END
			ELSE
			BEGIN
				SELECT @line_cnt = @cnt
				RETURN 1
			END
		END

	END
	--####################################################################################	
	--First Do validation
	--####################################################################################	

	--call console core stored procedure for validating part number
	--WMS uses UPC#, CS uses sku#
	SELECT @cust_code = cust_code 
	  FROM xfers (NOLOCK)  
         WHERE xfer_no   = @xfer_no
	
	IF @VerifyPart = 'NOTFOUND'
	BEGIN
		-- @err_msg = 'Part number not found'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_part_xfer_sp' AND err_no = -106 AND language = @language 
		RETURN -1
	END

	--Fill the location value
	SELECT @location = from_loc 
	  FROM xfer_list (NOLOCK)
	 WHERE xfer_no   = @xfer_no
	   AND line_no   = @line_no			

	--Initialize the serial flag
	SELECT @bPartIsSerialized = 0

	SELECT @vendor_sn = vendor_sn 
	  FROM tdc_inv_list (nolock)
	 WHERE part_no  = @part_no
   	   AND location = @location
		 
	SELECT @tdc_generated = tdc_generated 
	  FROM tdc_inv_master (nolock)   
	 WHERE part_no = @part_no

	--if lot/bin tracked then 
	SELECT @lb_tracking = lb_tracking
	  FROM inv_master (NOLOCK)
	 WHERE part_no = @part_no	

	IF ISNULL(@uom, '') = ''
	BEGIN
		SELECT @uom = uom
		  FROM xfer_list (NOLOCK)
		 WHERE xfer_no = @xfer_no
		   AND line_no = @line_no
	END

	IF(@serial_no_flg = 1)
	BEGIN
		IF @packing_flg = 1
		BEGIN
			IF @vendor_sn = 'I'
			BEGIN
				RETURN @ID_SCAN_SERIAL
			END
		END
		ELSE IF @vendor_sn IN ('I', 'O')
		BEGIN
			RETURN @ID_SCAN_SERIAL
		END
	END


	--If not in pick/pack mode, make sure that the part has been picked
	IF @packing_flg = 1 
	BEGIN
		IF NOT EXISTS(SELECT * 
			        FROM tdc_dist_item_pick (NOLOCK)
			       WHERE order_no   = @xfer_no
				 AND order_ext  = 0
				 AND line_no    = @line_no
				 AND part_no    = @part_no
				 AND quantity   > 0
				 AND [function] = 'T')
		AND @line_cnt = 1
		BEGIN
			-- @err_msg = 'Item has not been picked'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_part_xfer_sp' AND err_no = -107 AND language = @language 
			RETURN -1
		END

		--If packing from tote bins, verify that the part is in the tote
		IF @tote_bin <> '' 
		BEGIN				
			IF NOT EXISTS(SELECT * FROM tdc_tote_bin_tbl (NOLOCK)
				       WHERE order_no   = @xfer_no
					 AND order_ext  = 0
					 AND part_no    = @part_no
					 AND line_no    = @line_no
					 AND location   = @location
					 AND bin_no     = @tote_bin
					 AND order_type = 'T')
			BEGIN
				--If part does not exist, but exists at another location
				IF EXISTS(SELECT * FROM tdc_tote_bin_tbl (NOLOCK)
					   WHERE order_no   = @xfer_no
					     AND order_ext  = 0
					     AND part_no    = @part_no
					     AND line_no    = @line_no
					     AND bin_no     = @tote_bin
					     AND order_type = 'T')
				BEGIN
					-- @err_msg = 'Items in tote bin must be of the same location'
					SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_part_xfer_sp' AND err_no = -108 AND language = @language 
					RETURN -1
				END
				ELSE
				BEGIN
					-- @err_msg = 'Item not found in the tote bin'
					SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_part_xfer_sp' AND err_no = -109 AND language = @language 
					RETURN -1
				END
			END						
		END
	END

	--####################################################################################	
	--Determine which field to set focus to 
	--####################################################################################		
	
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
--			IF EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'auto_lot_part' AND active = 'Y')
--				SELECT @lot_ser = ISNULL((SELECT auto_lot FROM tdc_inv_master (nolock) WHERE part_no = @part_no), @auto_lot)
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
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_part_xfer_sp] TO [public]
GO
