SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_asn_po_receiving]
			@module		  varchar(3),
			@transaction 	  varchar(10),
		 	@mod_bac_registry char(1),
			@mod_3pl_registry char(1),
			@expert		  char(1),
			@err_msg	  varchar(255) output
AS

DECLARE @po_no			varchar(16), 
	@part_no		varchar(30), 
	@line_no		int, 
	@order_no		int,
	@row_id			int,
	@location		varchar(10), 
	@qty			decimal(20, 8), 
	@user_id		varchar(50), 
	@lot_ser		varchar(25), 
	@bin_no			varchar(12), 
	@bin_group		varchar(12), 
	@mask_code		varchar(15),
	@serial_no		varchar(50),
	@serial_raw		varchar(50),
	@date_expires		datetime, 
	@date_entered		datetime, 
	@qc_flag		char(1),
	@lb_tracking		char(1),
	@eBO_serial_flag	int,
	@eWH_serial_flag	int,
	@receipt_no		int,
	@ret_val		int,
	@qc_no			int,
	@sn_count		int,
	@po_uom			varchar(2),
	@uom_scanned		varchar(2),
	@uom_transmitted	varchar(2),
	@asn_conv_factor	decimal(20, 8),
	@qty_transmitted	decimal(20, 8),
	@q_tran_id		int,
	@asn_row_id		int,
	@ASN			varchar(50),
	@SSCC			varchar(18),
	@EPC_TAG		varchar(24),
	@carton_no		varchar(50),
	@vend_part		varchar(30),
	@qty_scanned		decimal(20,8),
	@vendor_no		varchar(12),
	@vendor_name		varchar(60), @item_upc_code	varchar(20)

DECLARE	@sku_code 		varchar(17),	@base_uom	varchar(2),
        @cmdty_code		varchar(9),	@description	varchar(255),
        @category1		varchar(15), 	@category2	varchar(15),
        @category3		varchar(15), 	@category4	varchar(15),
        @category5		varchar(15),	@upc		varchar(12),
        @ean8			varchar(8),	@GTIN		varchar(14),
        @ean13			varchar(13),	@ean14		varchar(14),		
	@height			decimal(20,8), 	@width		decimal(20,8), 
	@length			decimal(20,8), 	@weight_ea	decimal(20,8),
	@so_qty_increment 	decimal(20,8), 	@cubic_feet	decimal(20,8)

SET @ret_val = 0

BEGIN TRAN

DECLARE po_rec_cur CURSOR FOR
	SELECT po_no, part_no, line_no, location, quantity, who_entered, lot_ser, bin_no, date_expires, qc_flag, row_id, 
	       asn_row_id, asn_conv_factor, uom_scanned, qty_scanned
	  FROM #receipts

OPEN po_rec_cur
FETCH NEXT FROM po_rec_cur 
INTO @po_no, @part_no, @line_no, @location, @qty, @user_id, @lot_ser, @bin_no, @date_expires, @qc_flag, @row_id, 
     @asn_row_id, @asn_conv_factor, @uom_scanned, @qty_scanned

WHILE (@@FETCH_STATUS = 0 )
BEGIN
	SET @q_tran_id 	     	= 0	SET @receipt_no      	= 0
	SET @eBO_serial_flag 	= 0	SET @eWH_serial_flag 	= 0
	SET @lb_tracking     	= NULL	SET @bin_group 		= NULL
	SET @sku_code 		= NULL	SET @cmdty_code 	= NULL
	SET @category1 		= NULL	SET @description	= NULL
	SET @category2 		= NULL	SET @base_uom		= NULL
	SET @category3 		= NULL	SET @category4 		= NULL
	SET @category5 		= NULL	SET @upc		= NULL
	SET @GTIN       	= NULL	SET @ean8		= NULL
	SET @ean13      	= NULL	SET @ean14		= NULL
	SET @height 		= NULL	SET @width 		= NULL
	SET @cubic_feet		= NULL	SET @length 		= NULL
	SET @weight_ea 		= NULL	SET @so_qty_increment 	= NULL
	SET @po_uom    		= NULL

	SELECT @eBO_serial_flag = serial_flag, 	@lb_tracking      = lb_tracking,
               @sku_code  	= sku_code,	@cmdty_code 	  = cmdty_code,
	       @height    	= height,	@cubic_feet       = cubic_feet,
	       @width     	= width,	@weight_ea 	  = weight_ea,				 	        	  
   	       @length    	= length, 	@so_qty_increment = so_qty_increment, 
    	       @base_uom  	= uom,		@description	  = [description],
	       @item_upc_code   = upc_code
	  FROM inv_master (NOLOCK)
	 WHERE part_no = @part_no

	SELECT @po_uom = unit_measure
	  FROM pur_list (NOLOCK)
	 WHERE po_no   = @po_no
	   AND part_no = @part_no
	   AND status  = 'O'
	
	------------------------------------------------------
	-- Receive the row
	------------------------------------------------------
	IF @eBO_serial_flag = 1
		EXEC @receipt_no = tdc_ins_receipt_ser_batch_asn @err_msg OUTPUT
	ELSE
		EXEC @receipt_no = tdc_ins_receipt               @err_msg OUTPUT

	IF (@receipt_no <= 0)
	BEGIN
		CLOSE      po_rec_cur
		DEALLOCATE po_rec_cur
		ROLLBACK TRAN
		RETURN @receipt_no
	END

	------------------------------------------------------
	-- For EI
	------------------------------------------------------
	IF @mod_bac_registry = 'Y' AND @lb_tracking = 'Y'
	BEGIN
		INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, to_bin, userid, direction, quantity)
		VALUES(@module, @transaction, @receipt_no, 0, @location, @part_no, @bin_no, @user_id, 1, @qty)

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRAN

			CLOSE      po_rec_cur
			DEALLOCATE po_rec_cur
			SELECT @err_msg = 'Error Occured: insert INTO tdc_ei_bin_log failed'
			RETURN -2
		END		
	END

	------------------------------------------------------
	-- For 3PL
	------------------------------------------------------
	IF @mod_3pl_registry = 'Y'
	BEGIN
		IF @lb_tracking = 'Y' 
			SELECT @bin_group = group_code FROM tdc_bin_master (NOLOCK) WHERE location = @location AND bin_no = @bin_no

		INSERT INTO dbo.tdc_3pl_receipts_log 
			(trans, tran_no, tran_ext, receipt_no, location, part_no, bin_no, bin_group, uom, qty, userid, expert) 
		VALUES 	(@transaction, @po_no, 0, @receipt_no, @location, @part_no, @bin_no, @bin_group, @po_uom, @qty/@asn_conv_factor, @user_id, @expert)

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRAN

			CLOSE      po_rec_cur
			DEALLOCATE po_rec_cur
			SELECT @err_msg = 'Error Occured: insert into tdc_3pl_receipts_log failed'
			RETURN -3
		END		
	END

	IF @lb_tracking = 'Y'
	BEGIN
		SELECT @order_no = ISNULL((SELECT order_no FROM orders_auto_po (nolock) WHERE po_no = @po_no AND part_no = @part_no), 0)

		IF @order_no = 0
		BEGIN
			------------------------------------------------------
			-- For Q PO Putaway
			------------------------------------------------------
			IF @eBO_serial_flag = 1
				EXEC @q_tran_id = tdc_queue_po_batch_putaway_sp @receipt_no, @part_no, @bin_no, @qty, @lot_ser
			ELSE 
				EXEC @q_tran_id = tdc_queue_po_putaway_sp       @receipt_no, @part_no, @bin_no, @qty, @lot_ser
				
			IF (@q_tran_id < 0)
			BEGIN
				ROLLBACK TRAN

				CLOSE      po_rec_cur
				DEALLOCATE po_rec_cur
				RETURN -4
			END
		END

		SELECT @eWH_serial_flag = COUNT(*) FROM tdc_inv_list (NOLOCK) WHERE location = @location AND part_no = @part_no AND vendor_sn = 'I'

		------------------------------------------------------
		-- eWH Seralization
		------------------------------------------------------
		IF @eWH_serial_flag > 0	-- SN Capture is ON
		BEGIN
			SELECT @mask_code = mask_code  FROM tdc_inv_master (NOLOCK) WHERE part_no = @part_no

			IF @qc_flag = 'Y'
			BEGIN
				SELECT @qc_no = qc_no FROM qc_results (NOLOCK) WHERE tran_code = 'R' AND tran_no = @receipt_no				
			END
				
			-- Only for I/O Parts
			DECLARE sn_cursor CURSOR FOR
				SELECT DISTINCT s.serial_no, s.serial_raw,
						COUNTBY = (SELECT count(*)
							     FROM tdc_serial_no_track (NOLOCK)
							    WHERE part_no   = @part_no
							      AND lot_ser   = @lot_ser
							      AND serial_no = s.serial_no)
				  FROM #asn_serial_no s (NOLOCK)

			OPEN sn_cursor
			FETCH NEXT FROM sn_cursor INTO @serial_no, @serial_raw, @sn_count
	
			WHILE (@@FETCH_STATUS = 0 )
			BEGIN
				-- Insert INTO tdc_serial_no_track table
				IF @qc_flag = 'Y'
				BEGIN						
					IF @sn_count= 0
					BEGIN
						INSERT INTO tdc_serial_no_track 
							(location, transfer_location, part_no, lot_ser, mask_code, serial_no, serial_no_raw,
							 IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, 
							 last_trans, last_tx_control_no, date_time, [User_id])
						VALUES 	(@location, @location, @part_no, @lot_ser, @mask_code, @serial_no, @serial_raw, 1, '0', 
							 @transaction, @receipt_no, 'Q', 'QCHOLD', @qc_no, GETDATE(), @user_id)
					END
					ELSE
					BEGIN
						UPDATE tdc_serial_no_track
						   SET location 		= @location,
						       transfer_location 	= @location,
						       last_tx_control_no 	= @qc_no,
						       [User_id] 		= @user_id,
						       ARBC_No 			= NULL,
						       last_trans 		= 'QCHOLD',
						       last_control_type 	= 'Q',
						       IO_count 		= IO_count + 1,
						       date_time 		= GETDATE()
					 	 WHERE part_no 			= @part_no
					   	   AND lot_ser 			= @lot_ser
					   	   AND serial_no 		= @serial_no
					END
				END
				ELSE
				BEGIN
					IF(@order_no > 0) 
					BEGIN
						IF @sn_count = 0
						BEGIN
							INSERT INTO tdc_serial_no_track
								(location,transfer_location, part_no, lot_ser, mask_code,serial_no, serial_no_raw, 
								 IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, 
								 last_trans, last_tx_control_no, date_time, [User_id])
							VALUES (@location, @location, @part_no, @lot_ser, @mask_code, @serial_no, @serial_raw, 2, '0', 
								@transaction, @receipt_no, 'S', 'STDPICK', @order_no, GETDATE(), @user_id)
						END
						ELSE
						BEGIN
							UPDATE tdc_serial_no_track
							   SET location 		= @location,
							       transfer_location 	= @location,
							       init_trans 		= @transaction,
							       init_tx_control_no	= @receipt_no,
							       last_tx_control_no 	= @order_no,
							       [User_id] 		= @user_id,
							       last_trans 		= 'STDPICK',
							       last_control_type 	= 'S',
							       IO_count 		= IO_count + 2,
							       date_time 		= GETDATE()
						 	 WHERE part_no 			= @part_no
						   	   AND lot_ser 			= @lot_ser
						   	   AND serial_no 		= @serial_no
						END
					END
					ELSE
					BEGIN
						IF @sn_count = 0
						BEGIN
							INSERT INTO tdc_serial_no_track
								(location, transfer_location, part_no, lot_ser, mask_code, serial_no, serial_no_raw, 
								 IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, 
								 last_trans, last_tx_control_no, date_time, [User_id])
							VALUES (@location, @location, @part_no, @lot_ser, @mask_code, @serial_no, @serial_raw, 1,  '0', 
								@transaction, @receipt_no, '0', @transaction, @receipt_no, GETDATE(), @user_id)
						END
						ELSE
						BEGIN
							UPDATE tdc_serial_no_track
							   SET location 		= @location,
							       transfer_location 	= @location,
							       last_tx_control_no 	= @receipt_no,
							       [User_id] 		= @user_id,
							       last_trans 		= @transaction,
							       last_control_type 	= '0',
							       IO_count 		= IO_count + 1, 
							       date_time 		= GETDATE()
						 	 WHERE part_no 			= @part_no
						   	   AND lot_ser 			= @lot_ser
						   	   AND serial_no 		= @serial_no
						END
					END
				END

				IF @@ERROR <> 0 
				BEGIN
					ROLLBACK TRAN
		
					CLOSE      po_rec_cur
					DEALLOCATE po_rec_cur
					CLOSE      sn_cursor
					DEALLOCATE sn_cursor
					SELECT @err_msg = 'Error Occured: insert/update tdc_serial_no_track failed'
					RETURN -5
				END		

				FETCH NEXT FROM sn_cursor INTO @serial_no, @serial_raw, @sn_count
			END

			CLOSE	   sn_cursor
			DEALLOCATE sn_cursor
		END
	END
	ELSE
	BEGIN
		SET @lot_ser = NULL
		SET @bin_no  = NULL
	END

	--------------------------------------------------------------------
	-- Update the ASN tables
	--------------------------------------------------------------------

	-- Get all the ASN fields for the rowID to use for history and printing
	SELECT @ASN 		= ASN, 
               @SSCC 		= SSCC, 
               @GTIN            = GTIN, 
               @EPC_TAG         = EPC_TAG,  
               @carton_no       = carton_no, 
               @vend_part	= vend_part, 
               @date_entered    = date_entered,
	       @qty_transmitted = qty_transmitted,
	       @uom_transmitted = uom
          FROM tdc_inbound_ASN (NOLOCK)
         WHERE row_id = @asn_row_id

	IF @transaction = 'RCVASNMAN'	-- Manual ASN Receiving
	BEGIN
		-- Update manually received qty
		UPDATE tdc_inbound_ASN
		   SET qty_manual_rcv = ISNULL(qty_manual_rcv , 0) + @qty
	         WHERE row_id = @asn_row_id	

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRAN

			CLOSE      po_rec_cur
			DEALLOCATE po_rec_cur
			SELECT @err_msg = 'Error Occured: update tdc_inbound_ASN failed'
			RETURN -6
		END	

		-- Insert into the History table
		INSERT INTO tdc_inbound_ASN_history
		       (ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted,  
		        uom, qty_manual_rcv, date_entered, receipt_no, tran_date, userid, trans)
		VALUES (@ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, @qty_transmitted, 
		        @uom_transmitted, @qty, @date_entered, @receipt_no, GETDATE(), @user_id, @transaction)

		IF @eBO_serial_flag = 1 OR @eWH_serial_flag = 1
		BEGIN
			-- Insert into the Serial History table
			INSERT INTO tdc_inbound_ASN_serial_history
			      (ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no, 
			       date_entered, receipt_no, tran_date, userid, trans)
			SELECT @ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, serial_no, 
			       @date_entered, @receipt_no, GETDATE(), @user_id, @transaction
		          FROM #asn_serial_no
		END

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRAN
	
			CLOSE      po_rec_cur
			DEALLOCATE po_rec_cur
			SELECT @err_msg = 'Error Occured: insert into tdc_inbound_ASN_history failed'
			RETURN -7
		END	

		-- Remove the ASN record when the entire qty is received
		DELETE FROM tdc_inbound_ASN WHERE row_id = @asn_row_id AND qty_transmitted = qty_manual_rcv / @asn_conv_factor
	END
	ELSE
	BEGIN
		-- Insert into the History table (without qty_manul_rcv)
		INSERT INTO tdc_inbound_ASN_history
		       (ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted,  
		        uom, date_entered, receipt_no, tran_date, userid, trans)
		VALUES (@ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, @qty_transmitted, 
		        @uom_transmitted, @date_entered, @receipt_no, GETDATE(), @user_id, @transaction)

		IF @eBO_serial_flag = 1 OR @eWH_serial_flag = 1
		BEGIN
			-- Insert into the Serial History table (without qty_manul_rcv)
			INSERT INTO tdc_inbound_ASN_serial_history
			      (ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no, 
			       date_entered, receipt_no, tran_date, userid, trans)
			SELECT @ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, serial_no, 
			       @date_entered, @receipt_no, GETDATE(), @user_id, @transaction
		          FROM #asn_serial_no
		END

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRAN
	
			CLOSE      po_rec_cur
			DEALLOCATE po_rec_cur
			SELECT @err_msg = 'Error Occured: insert into tdc_inbound_ASN_history failed'
			RETURN -7
		END	
	
		-- Remove the ASN record
		DELETE FROM tdc_inbound_ASN WHERE row_id = @asn_row_id
	END

	-- Delete the received Serial Numbers from the ASN Serial table
	DELETE FROM tdc_inbound_ASN_serial
	  FROM tdc_inbound_ASN_serial a,
	       #asn_serial_no         b
	 WHERE a.ASN       = @ASN
           AND ISNULL(a.SSCC,      '') = ISNULL(@SSCC,      '')
           AND ISNULL(a.carton_no, '') = ISNULL(@carton_no, '')
           AND ISNULL(a.GTIN,      '') = ISNULL(@GTIN,      '')
           AND ISNULL(a.EPC_TAG,   '') = ISNULL(@EPC_TAG,   '')
           AND a.po_no     = @po_no
           AND a.part_no   = @part_no
           AND ISNULL(a.lot_ser, '')   = ISNULL(@lot_ser, '')
	   AND a.serial_no = b.serial_no

	--------------------------------------------------------------------
	-- Get the rest of data for printing
	--------------------------------------------------------------------
	SELECT @vendor_no   = r.vendor,
	       @vendor_name = a.vendor_name
          FROM receipts r (NOLOCK),
	       apvend   a (NOLOCK)
	 WHERE r.receipt_no  = @receipt_no
	   AND a.vendor_code = r.vendor

	SELECT @category1 = category_1, @category2 = category_2, @category3 = category_3, 
	       @category4 = category_4, @category5 = category_5
	  FROM inv_master_add (NOLOCK)
         WHERE part_no = @part_no

	SELECT @upc  = UPC, @ean8 = EAN_8, @ean13 = EAN_13, @ean14 = EAN_14
	  FROM uom_id_code (NOLOCK) 
         WHERE part_no = @part_no 
           AND UOM     = @uom_scanned

	IF ISNULL(@base_uom, '') = '' SET @base_uom = @uom_scanned

	INSERT INTO #print_header (field, value) VALUES('LP_USER_STAT_ID',	@user_id)
	INSERT INTO #print_header (field, value) VALUES('LP_LOCATION',		@location)
	INSERT INTO #print_header (field, value) VALUES('LP_PO',		@po_no)
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM',		@part_no)
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM_DESC',		@description)
	INSERT INTO #print_header (field, value) VALUES('LP_LB_TRACKING',	@lb_tracking)
	INSERT INTO #print_header (field, value) VALUES('LP_QC_FLAG',		@qc_flag)
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM_UOM',		@uom_scanned)
	INSERT INTO #print_header (field, value) VALUES('LP_PO_UOM',		@po_uom)
	INSERT INTO #print_header (field, value) VALUES('LP_BASIC_UOM',		@base_uom)
	INSERT INTO #print_header (field, value) VALUES('LP_LINE_NO',		CAST  (@line_no    AS varchar		     ))  
	INSERT INTO #print_header (field, value) VALUES('LP_QUANTITY',		CAST  (@qty        AS varchar		     ))
	INSERT INTO #print_header (field, value) VALUES('LP_RECEIPT_NO',	CAST  (@receipt_no AS varchar 		     ))
	INSERT INTO #print_header (field, value) VALUES('LP_BIN',		ISNULL(@bin_no,  	 		   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_LOT',		ISNULL(@lot_ser, 	 		   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_EXP_DATE',		ISNULL(@date_expires, 	 		   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_VENDOR_NO',		ISNULL(@vendor_no, 	   		   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_VENDOR_NAME',	ISNULL(@vendor_name, 	   		   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM_UPC',		ISNULL(@item_upc_code, 	           	   ''))	
	INSERT INTO #print_header (field, value) VALUES('LP_SKU',		ISNULL(@sku_code, 			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_CMDTY_CODE',	ISNULL(@cmdty_code,			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_CATEGORY_1',	ISNULL(@category1,			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_CATEGORY_2',	ISNULL(@category2,			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_CATEGORY_3',	ISNULL(@category3,			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_CATEGORY_4',	ISNULL(@category4,			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_CATEGORY_5',	ISNULL(@category5,			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM_UPC',		ISNULL(@upc,				   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM_GTIN',		ISNULL(@GTIN,				   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM_EAN8',		ISNULL(@ean8,				   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM_EAN13',	ISNULL(@ean13,				   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_ITEM_EAN14',	ISNULL(@ean14,				   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_QC_NO',		ISNULL(CAST(@qc_no            AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_Q_ID',		ISNULL(CAST(@q_tran_id        AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_UOM_QTY',		ISNULL(CAST(@qty_scanned      AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_HEIGHT',		ISNULL(CAST(@height 	      AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_WIDTH',		ISNULL(CAST(@width  	      AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_LENGTH',		ISNULL(CAST(@length 	      AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_WEIGHT',		ISNULL(CAST(@weight_ea 	      AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_SO_QTY_INCR',	ISNULL(CAST(@so_qty_increment AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_CUBIC_FEET',	ISNULL(CAST(@cubic_feet       AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_QTY_TRANSMIT',	ISNULL(CAST(@qty_transmitted  AS varchar), ''))
	INSERT INTO #print_header (field, value) VALUES('LP_ASN',		ISNULL(@ASN, 				   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_SSCC',		ISNULL(@SSCC,     			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_EPC_TAG',		ISNULL(@EPC_TAG,     			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_ASN_CARTON',	ISNULL(@carton_no, 			   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_UOM_TRANSMIT',	ISNULL(@uom_transmitted, 		   ''))
	INSERT INTO #print_header (field, value) VALUES('LP_VEND_PART',		ISNULL(@vend_part,                         ''))	
	INSERT INTO #print_header (field, value) VALUES('END_OF_FILE',		'END_OF_FILE')	
	-- NOTE: need to insert the END_OF_FILE for Auto ASN Receiving labels

	-- Store the serails for each part
	INSERT INTO #print_part_serial (part_no, serial, serial_no, serial_raw)
	SELECT @part_no, serial_no, serial_no, serial_no
	  FROM #asn_serial_no

	--------------------------------------------------------------------
	-- Clear the variables
	--------------------------------------------------------------------
	SET @po_no    = NULL SET @part_no = NULL SET @line_no      = NULL 
	SET @location = NULL SET @qty     = NULL SET @user_id      = NULL 
	SET @lot_ser  = NULL SET @bin_no  = NULL SET @date_expires = NULL 
	SET @qc_flag  = NULL SET @row_id  = NULL SET @q_tran_id    = 0
	SET @asn_row_id = 0  SET @asn_conv_factor = 0

	FETCH NEXT FROM po_rec_cur 
	INTO @po_no, @part_no, @line_no, @location, @qty, @user_id, @lot_ser, @bin_no, @date_expires, @qc_flag, @row_id, 
             @asn_row_id, @asn_conv_factor, @uom_scanned, @qty_scanned
END	

CLOSE	   po_rec_cur
DEALLOCATE po_rec_cur

COMMIT TRAN

RETURN @receipt_no
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_po_receiving] TO [public]
GO
