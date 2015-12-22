SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_recv_asn_sp]
	@user_id 		varchar (50),
	@bin_no 		varchar (12),
	@modBAC_Registered 	char(1),
	@mod3PL_Registered 	char(1),
	@expert 		char(1),
	@module		  	varchar(3),
	@trans			varchar (10),
	@recv_location		varchar (10) = NULL
AS

DECLARE @row_id 	 	int,
	@ret 		 	int,
	@date_expires 	 	datetime,
	@receipt_no	 	int,
	@po_no		 	varchar(16),
	@part_no	 	varchar(30),
	@line_no	 	int,
	@location	 	varchar(10),
	@auto_drop_loc	 	varchar(10),
	@recv_date	 	datetime,
	@who_entered	 	varchar(50),
	@lot_ser	 	varchar(25),
	@qc_flag	 	char(1),
	@uom_transmitted 	varchar(2),
	@uom		 	varchar(2),
	@cnt		 	int,
	@vendor_sn	 	char(1),
	@err_msg	 	varchar(255),
	@err_found	 	char(1),
	@po_uom		 	varchar(2),
	@uom_voided_flag 	char(1),
	@base_uom 	 	varchar(2),
	@part_type 	 	char(1),
	@lb_tracking	 	char(1),
	@auto_drop_bin	 	varchar(12),
	@conv_factor 	 	decimal(20,8),
	@qty_manual_rcv  	decimal(20,8),
	@qty_transmitted 	decimal(20,8),
	@base_qty	 	decimal(20,8),
	@months_exp	 	int,
	@eBO_tracking	 	int,
	@eWH_tracking	 	int,
	@auto_sn_generate	int,
	@mask_code	 	varchar(15),
	@ASN			varchar(50),
	@SSCC			varchar(18),
	@carton_no		varchar(50),
	@GTIN			varchar(14),
	@EPC_TAG		varchar(24)

-- Get date_exp
SELECT @months_exp = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'adj_date_expire'	
IF ISNULL(@months_exp, 0) = 0 SET @months_exp = 12
SELECT @date_expires = DATEADD(MONTH, @months_exp, GETDATE())
 
DECLARE selected_cur CURSOR FOR 
	SELECT row_id, po_no, part_no, lot_ser, uom, qty_transmitted, qty_manual_rcv,
               ASN, SSCC, GTIN, EPC_TAG, carton_no
          FROM #temp_inbound_ASN 
	 WHERE sel_flg = -1
	 ORDER BY asn

--TEMP TABLE MUST BE CLEARED BY THE CALLER.
--TRUNCATE TABLE #inbound_errors

OPEN selected_cur
FETCH NEXT FROM selected_cur 
INTO @row_id, @po_no, @part_no, @lot_ser, @uom_transmitted, @qty_transmitted, @qty_manual_rcv, @ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no
		
WHILE @@FETCH_STATUS = 0
BEGIN	
	---------------------------------------------------------------
	-- For RFID grid
	---------------------------------------------------------------
	UPDATE #temp_inbound_ASN SET sel_flg = 0 where row_id = @row_id

	---------------------------------------------------------------
	-- Clear the variables
	---------------------------------------------------------------
	TRUNCATE TABLE #receipts
	TRUNCATE TABLE #serial_no
	TRUNCATE TABLE #asn_serial_no

	SET @err_found 		= 'N' 
	SET @line_no 		= NULL
	SET @qc_flag 		= NULL
	SET @lb_tracking 	= NULL
	SET @eBO_tracking	= 0
	SET @eWH_tracking	= 0
	SET @auto_sn_generate	= 0

	---------------------------------------------------------------
	-- Validate UOM
	---------------------------------------------------------------
	IF @err_found = 'N'
	BEGIN
		IF @uom_transmitted IS NULL OR @uom_transmitted = ''
		BEGIN
			IF @part_type = 'M'
			BEGIN
				SELECT @uom         = @po_uom 
				SELECT @conv_factor = 1
			END
			ELSE
			BEGIN
				SELECT @uom = uom FROM inv_master (NOLOCK) WHERE part_no = @part_no
			END
		END
		ELSE
		BEGIN
			SET @uom = @uom_transmitted
		END

		-- If the config flag is off, the entered uom_transmitted cannot be different fot the pur_list uom_transmitted
		IF (SELECT active FROM tdc_config WHERE [function] = 'po_unit_of_measure') = 'N'
		AND @uom <> @uom_transmitted
		BEGIN
			SET @err_msg   = 'UOM must match PO uom if config flag PO_UNIT_OF_MEASURE is not set'
			SET @err_found = 'Y'
		END
	END

	IF @err_found = 'N'
	BEGIN
		-- Make sure that entered uom_transmitted is a valid uom_transmitted in the system
		SELECT @uom_voided_flag = void FROM uom_list (NOLOCK) WHERE uom = @uom

		IF @uom_voided_flag IS NULL OR @uom_voided_flag = ''
		BEGIN
			SET @err_msg   = 'Invalid UOM'
			SET @err_found = 'Y'
		END

		IF @uom_voided_flag = 'Y'
		BEGIN
			SET @err_msg   = 'UOM Is Voided'
			SET @err_found = 'Y'
		END
	
		IF @err_found = 'N'
		BEGIN
			-- Get base uom_transmitted
			IF @part_type = 'M'
			BEGIN
				SELECT @base_uom = @uom		
			END
			ELSE
			BEGIN
				SELECT @base_uom = uom FROM inv_master (NOLOCK) WHERE part_no = @part_no
			END

			-- Make sure that the entered UOM and the std uom are the same category
			IF (@base_uom <> @uom)
			BEGIN
				IF NOT EXISTS (SELECT *				
				                 FROM uom_table (NOLOCK)		 
				 		WHERE item IN ('STD', @part_no)
						  AND std_uom = @base_uom			 
				   		  AND alt_uom = @uom)
				BEGIN
					SET @err_msg   = 'Invalid UOM'
					SET @err_found = 'Y'
				END
			END
		END
	END
	 
	---------------------------------------------------------------
	-- Convert transmitted qty to base qty
	---------------------------------------------------------------
	IF @err_found = 'N'
	BEGIN
		SET @conv_factor = 0
		IF @base_uom = @uom SET @conv_factor = 1

		IF @conv_factor = 0
		BEGIN
			IF EXISTS(SELECT *			
		                    FROM uom_table (NOLOCK)		 
		 		   WHERE item    = @part_no
				     AND std_uom = @base_uom			 
	   		             AND alt_uom = @uom)
			BEGIN
				SELECT @conv_factor = conv_factor				
		                  FROM uom_table (NOLOCK)		 
		 		 WHERE item    = @part_no
				   AND std_uom = @base_uom			 
		   		   AND alt_uom = @uom		
			END
		END

		IF @conv_factor = 0
		BEGIN
			if EXISTS(SELECT *			
		                  FROM uom_table (NOLOCK)		 
		 		 WHERE item    = 'STD'
				   AND std_uom = @base_uom			 
		   		   AND alt_uom = @uom)
			BEGIN
				SELECT @conv_factor = conv_factor				
		                  FROM uom_table (NOLOCK)		 
		 		 WHERE item    = 'STD'
				   AND std_uom = @base_uom			 
		   		   AND alt_uom = @uom	 
			END
		END

		IF @conv_factor = 0
		BEGIN
			SET @err_msg   = 'Conversion Factor is not found'
			SET @err_found = 'Y'
		END
		ELSE
		BEGIN
			SET @base_qty = @qty_transmitted * @conv_factor - ISNULL(@qty_manual_rcv, 0)
		END

		IF @base_qty = 0
		BEGIN
			SET @err_msg   = 'Quantity must be greater than 0'
			SET @err_found = 'Y'
		END
	END

	IF @err_found = 'N'
	BEGIN
		---------------------------------------------------------------
		-- Get Line and Location
		---------------------------------------------------------------
		-- get the number of lines for this part/uom
		SELECT @cnt = COUNT(*) 
	          FROM pur_list (NOLOCK)
		 WHERE po_no        = @po_no
		   AND part_no      = @part_no
		   AND unit_measure = @uom_transmitted

		IF @cnt = 1 -- use this part-uom
		BEGIN
			SELECT @line_no  = line, 
                               @location = location 
			  FROM pur_list (NOLOCK) 
			 WHERE po_no        = @po_no
			   AND part_no      = @part_no
			   AND unit_measure = @uom_transmitted
		END
		ELSE -- GET the first line with this part
		BEGIN
			SELECT TOP 1 @line_no  = line, 
                                     @location = location 
			  FROM pur_list(NOLOCK) 
			 WHERE po_no   = @po_no
			   AND part_no = @part_no 
		END

		---------------------------------------------
		-- For auto drop ship order
		---------------------------------------------
		SET @auto_drop_loc = NULL
		SELECT @auto_drop_loc = location 
	          FROM orders_auto_po (NOLOCK) 
	         WHERE po_no   = @po_no 
		   AND part_no = @part_no 
		   AND status  < 'R' 

		IF @auto_drop_loc IS NOT NULL	-- The PO is auto drop ship
		BEGIN
			IF @auto_drop_loc = 'DROP'
			BEGIN
				SET @auto_drop_bin = NULL
				SELECT @auto_drop_bin = bin_no FROM inv_list (NOLOCK) WHERE part_no = @part_no  AND location = @auto_drop_loc
				
				IF @auto_drop_bin IS NULL
				BEGIN
					SET @auto_drop_bin = 'N/A'
				END
			END
		END
		ELSE				-- Not auto drop ship
		BEGIN
			------------------------------------------------------------------
			-- If receipt location was passed in, use it (Auto ASN receiving)
			------------------------------------------------------------------
			IF @recv_location IS NOT NULL
			BEGIN
				IF (SELECT value_str FROM config (NOLOCK) WHERE flag = 'RECV_LOC_OVERRIDE') = 'YES'
				BEGIN
					SET @location = @recv_location
				END
			END
		END

		---------------------------------------------------------------
		-- Get flags for the part
		---------------------------------------------------------------	
		SELECT @qc_flag      = qc_flag,
		       @lb_tracking  = lb_tracking,
		       @eBO_tracking = serial_flag
	          FROM inv_master (NOLOCK)
	         WHERE part_no = @part_no

		IF @lb_tracking = 'Y'
		BEGIN
			SELECT @eWH_tracking = COUNT(*)
	                  FROM tdc_inv_list (NOLOCK) 
			 WHERE location  = @location 
	                   AND part_no   = @part_no 
	                   AND vendor_sn = 'I'
	
			SELECT @auto_sn_generate = tdc_generated 
		          FROM tdc_inv_master(NOLOCK) 
		         WHERE part_no = @part_no

			---------------------------------------------------------------
			-- Get Serial Numbers for the part/lot
			---------------------------------------------------------------	
			IF @auto_sn_generate = 1
			BEGIN
			 	IF @eBO_tracking = 1 
				BEGIN
					-- This SP will generate SNs ans will insert them into the #serial_no temp table
					EXEC tdc_generate_epicor_sn @part_no, @base_qty, @location

					-- Store the SNs in the #asn_serial_no table for the tdc_asn_po_receiving SP
					INSERT INTO #asn_serial_no (serial_no) SELECT serial FROM #serial_no
				END
			 	IF @eWH_tracking > 0 
				BEGIN
					SELECT @mask_code = mask_code FROM tdc_inv_master (NOLOCK) WHERE part_no = @part_no			
			
					-- This SP will generate SNs ans will insert them into the #serial_no temp table
					EXEC @ret = tdc_get_next_sn_sp @part_no, @base_qty, @location

					-- Store the SNs in the #asn_serial_no table for the tdc_asn_po_receiving SP
					INSERT INTO #asn_serial_no (serial_no, serial_raw) SELECT serial_no, serial_raw FROM #serial_no

					IF @ret < 0
					BEGIN
						SELECT @err_msg = 'Generate serial number failed!'
						SET @err_found = 'Y'
					END
				END
			END
			ELSE
			BEGIN	
				-- Use the transmitted serial numbers
				INSERT INTO #asn_serial_no (serial_no, serial_raw)
				SELECT serial_no, serial_no
				  FROM tdc_inbound_ASN_serial
				 WHERE ASN     = @ASN
				   AND ISNULL(SSCC,      '') = ISNULL(@SSCC,      '')
				   AND ISNULL(carton_no, '') = ISNULL(@carton_no, '')
				   AND ISNULL(GTIN,      '') = ISNULL(@GTIN,      '')
				   AND ISNULL(EPC_TAG,   '') = ISNULL(@EPC_TAG,   '')
				   AND po_no   = @po_no
				   AND part_no = @part_no
				   AND ISNULL(lot_ser,   '') = ISNULL(@lot_ser,   '')
			END
		END
	END

	IF @err_found = 'N'
	BEGIN
		---------------------------------------------------------------
		-- Receive the line
		---------------------------------------------------------------	
		IF @auto_drop_loc IS NOT NULL
		BEGIN
			INSERT #receipts (po_no, part_no, line_no, location, recv_date, quantity, who_entered, lot_ser, bin_no, date_expires, qc_flag, 
					  asn_row_id, asn_conv_factor, uom_scanned, qty_scanned)
			SELECT @po_no, @part_no,  @line_no, @auto_drop_loc, GETDATE(), @base_qty, @user_id, @lot_ser, @auto_drop_bin, @date_expires, @qc_flag, 
			       @row_id, 1, @uom_transmitted, @qty_transmitted - ISNULL(@qty_manual_rcv, 0)
	 	END
		ELSE
 		BEGIN
			INSERT #receipts (po_no, part_no, line_no, location, recv_date, quantity, who_entered, lot_ser, bin_no, date_expires, qc_flag, 
					  asn_row_id, asn_conv_factor, uom_scanned, qty_scanned)
			SELECT @po_no, @part_no,  @line_no, @location, GETDATE(), @base_qty, @user_id, @lot_ser, @bin_no, @date_expires, @qc_flag, 
			       @row_id, 1, @uom_transmitted, @qty_transmitted - ISNULL(@qty_manual_rcv, 0)
	 	END
 
		EXEC @ret = tdc_asn_po_receiving @module, @trans, @modBAC_Registered, @mod3PL_Registered, @expert, @err_msg output

		IF @ret < 0  
		BEGIN
			IF NOT EXISTS(SELECT * FROM #inbound_errors WHERE row_id = @row_id)
			BEGIN
				INSERT #inbound_errors (row_id, err_msg) SELECT @row_id, @err_msg
			END
		END
	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT * FROM #inbound_errors WHERE row_id = @row_id)
		BEGIN
			INSERT #inbound_errors (row_id, err_msg) SELECT @row_id, @err_msg
		END
 	END

	SET @row_id          = 0
	SET @po_no           = NULL
	SET @part_no         = NULL
	SET @lot_ser         = NULL
	SET @uom_transmitted = NULL
	SET @qty_transmitted = NULL
	SET @qty_manual_rcv  = NULL

	FETCH NEXT FROM selected_cur 
	INTO @row_id, @po_no, @part_no, @lot_ser, @uom_transmitted, @qty_transmitted, @qty_manual_rcv, @ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no
END

CLOSE      selected_cur
DEALLOCATE selected_cur

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_recv_asn_sp] TO [public]
GO
