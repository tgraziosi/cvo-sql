CREATE TABLE [dbo].[tdc_inbound_ASN_serial]
(
[ASN] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SSCC] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GTIN] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPC_TAG] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carton_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serial_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NOT NULL CONSTRAINT [DF__tdc_inbou__date___4CAAB6CD] DEFAULT (getdate())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_inbound_ASN_serial_ins_tg] ON [dbo].[tdc_inbound_ASN_serial]
FOR INSERT
AS

DECLARE @ASN			varchar(50),
	@SSCC			varchar(18),
	@GTIN			varchar(14),
	@EPC_TAG		varchar(24),
	@carton_no		varchar(50),
	@part_no		varchar(30),
	@vend_part		varchar(30),
	@po_no			varchar(16),
	@lot_ser		varchar(25),
	@serial_no		varchar(50),
	@lb_tracking		char(1),
	@err_found		char(1),
	@err_msg		varchar(255),
	@eBO_tracking		int,
	@eWH_tracking		int


-- Cursor through each record 
DECLARE ASN_Cursor CURSOR FOR
	SELECT ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no
	  FROM inserted

OPEN ASN_Cursor
FETCH NEXT FROM ASN_Cursor INTO @ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, @serial_no

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Clear the temp variables
	SET @err_found    = 'N'
	SET @err_msg      = NULL
	SET @lb_tracking  = NULL
	SET @eBO_tracking = NULL
	SET @eWH_tracking = NULL

	SELECT @lb_tracking  = lb_tracking,
	       @eBO_tracking = serial_flag
          FROM inv_master (NOLOCK) 
         WHERE part_no = @part_no


	-- 1. Only L/B tracked parts can be inserted in the table
	IF ISNULL(@lb_tracking, '') <> 'Y'
	BEGIN
		SET @err_msg   = 'Only Lot/Bin Tracked parts can be inserted'
		SET @err_found = 'Y'
	END

	-- 2. Only Fully (eBO) Serialized or I/O Tracked parts can be inserted in the table
	IF @err_found = 'N'
	BEGIN
		IF @eBO_tracking <> 1
		BEGIN
			-- Make sure that at least one location has this part I/O tracked
			SELECT @eWH_tracking = COUNT(*) FROM tdc_inv_list (NOLOCK) WHERE part_no = @part_no AND vendor_sn = 'I'

			IF @eWH_tracking = 0
			BEGIN
				SET @err_msg   = 'Only Fully Serialized or Inbound/Outbound Tracked parts can be inserted'
				SET @err_found = 'Y'				
			END
		END
	END

	-- 3. Check that ASN is inserted
	IF @err_found = 'N'
	BEGIN
		IF @ASN IS NULL OR @ASN = ''
		BEGIN
			SET @err_msg   = 'ASN is required'
			SET @err_found = 'Y'
		END
	END

	-- 4. Check that at least one of SSCC or carton_no is inserted
	IF @err_found = 'N'
	BEGIN
		IF @SSCC IS NULL OR @SSCC = ''
		BEGIN
			IF (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'ASN_SCAN_SSCC') = 'Y'
			BEGIN
				SET @err_msg   = 'SSCC is required'
				SET @err_found = 'Y'
			END
			ELSE
			BEGIN
				IF @carton_no IS NULL OR @carton_no = ''
				BEGIN		
					SET @err_msg   = 'SSCC or Carton Number is required'
					SET @err_found = 'Y'
				END
			END
		END
	END
 
	-- 5. Check that part_no or vend_part is inserted
	IF @err_found = 'N'
	BEGIN
		IF @part_no IS NULL OR @part_no = ''
		BEGIN
			IF LEN(@vend_part) > 0
			BEGIN
				

				SELECT @part_no = (SELECT DISTINCT sku_no 
						     FROM vendor_sku (NOLOCK)
                                                    WHERE vendor_no = (SELECT vendor_no FROM purchase (NOLOCK) WHERE po_no = @po_no) 
                                                      AND vend_sku  = @vend_part)
			END

			IF @part_no IS NULL OR @part_no = ''
			BEGIN
				SET @err_msg   = 'Part is required'
				SET @err_found = 'Y'
			END
		END
	END

	-- 6. Validate Lot
	IF @err_found = 'N'
	BEGIN
		-- For Fully Serialized parts Lot should not be transmitted
		IF @eBO_tracking = 1
		BEGIN
			IF LEN(@lot_ser) > 0
			BEGIN
				SET @err_msg   = 'Lot should not be transmitted for Fully Serialized parts'
				SET @err_found = 'Y'
			END
		END

		IF @err_found = 'N'
		BEGIN
			-- For I/O Tracked parts Lot is required (the user can be prompted for Lot at manual ASN receiving)
			IF @eWH_tracking = 1
			BEGIN
				IF @lot_ser IS NULL OR @lot_ser = ''		-- Check if AutoLot is on for the part
				BEGIN
					SELECT @lot_ser = auto_lot FROM tdc_inv_master (NOLOCK) WHERE part_no = @part_no AND auto_lot_flag = 'Y'	
	
					IF @lot_ser IS NULL OR @lot_ser = ''	-- Check if AutoLot is on for the system
					BEGIN
						SELECT @lot_ser = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'AUTO_LOT' AND active = 'Y'
					END
				END
			END
		END
	END

	-- 7. Validate Serial Number
	IF @err_found = 'N'
	BEGIN
		-- If part is Auto Generated, Serial No should not be transmitted (for both eBO and eWH tracked parts)
		IF (SELECT tdc_generated FROM tdc_inv_master (NOLOCK) WHERE part_no = @part_no) = 1 AND LEN(@serial_no) > 0
		BEGIN
			SET @err_msg   = 'Serial Number should not be transmitted for Auto SN Generated parts'
			SET @err_found = 'Y'
		END
	END

	-- Reject the current record or update with new Part, Lot
	IF @err_found = 'Y'
	BEGIN
		-- Reject the current record
		INSERT INTO tdc_inbound_ASN_serial_err (ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no, date_entered, err_msg)
		VALUES (@ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, @serial_no, GETDATE(), @err_msg)

		-- Move all the accpted ASN Serails records into the Serial error table
		INSERT INTO tdc_inbound_ASN_serial_err (ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no, date_entered)
		SELECT ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no, date_entered
		  FROM tdc_inbound_ASN_serial
		 WHERE ASN  = @ASN
		   AND (ISNULL(SSCC, '')   + '<->' + ISNULL(GTIN,    '')  + '<->' + ISNULL(EPC_TAG, '')  + '<->' + ISNULL(carton_no, '')  + '<->' +
		        ISNULL(po_no, '')  + '<->' + ISNULL(part_no, '')  + '<->' + ISNULL(lot_ser, '')  + '<->' + ISNULL(serial_no, ''))
                   !=
		       (ISNULL(@SSCC, '')  + '<->' + ISNULL(@GTIN,    '') + '<->' + ISNULL(@EPC_TAG, '') + '<->' + ISNULL(@carton_no, '') + '<->' +
		        ISNULL(@po_no, '') + '<->' + ISNULL(@part_no, '') + '<->' + ISNULL(@lot_ser, '') + '<->' + ISNULL(@serial_no, ''))

		-- Move all the accpted ASN records into the error table
		INSERT INTO tdc_inbound_ASN_err(ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted, uom, note, date_entered, err_msg)
		SELECT ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted, uom, 'Transmitting Serials Filed', date_entered, NULL
		  FROM tdc_inbound_ASN
		 WHERE ASN = @ASN

		DELETE FROM tdc_inbound_ASN_serial WHERE ASN = @ASN
		DELETE FROM tdc_inbound_ASN        WHERE ASN = @ASN
	END
	ELSE
	BEGIN	
		-- If at least one line of the ASN has already been rejected, reject the rest of the ASN
		IF EXISTS (SELECT * FROM tdc_inbound_ASN_err        WHERE ASN = @ASN) 
		OR EXISTS (SELECT * FROM tdc_inbound_ASN_serial_err WHERE ASN = @ASN)
		BEGIN
			INSERT INTO tdc_inbound_ASN_serial_err(ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no, note, date_entered, err_msg)
			VALUES (@ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, @serial_no, NULL, GETDATE(), NULL)

			DELETE FROM tdc_inbound_ASN_serial WHERE ASN = @ASN
		END
		ELSE
		BEGIN
			UPDATE tdc_inbound_ASN_serial
			   SET part_no  = @part_no,
			       lot_ser  = @lot_ser
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

	-- Clear the variables for the next record
	SET @ASN 	= NULL SET @SSCC      = NULL
	SET @GTIN	= NULL SET @EPC_TAG   = NULL		
	SET @carton_no	= NULL SET @po_no     = NULL 
	SET @part_no	= NULL SET @vend_part = NULL 
	SET @lot_ser	= NULL SET @lot_ser   = NULL
	
	FETCH NEXT FROM ASN_Cursor INTO @ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, @serial_no
END

CLOSE      ASN_Cursor
DEALLOCATE ASN_Cursor

RETURN
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_serial_indx1] ON [dbo].[tdc_inbound_ASN_serial] ([ASN], [SSCC], [carton_no], [po_no], [part_no], [lot_ser], [serial_no], [GTIN], [EPC_TAG]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_inbound_ASN_serial] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_inbound_ASN_serial] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_inbound_ASN_serial] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_inbound_ASN_serial] TO [public]
GO
