CREATE TABLE [dbo].[tdc_inbound_ASN]
(
[ASN] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_inbou__statu__45FDB93E] DEFAULT ('A'),
[SSCC] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GTIN] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPC_TAG] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carton_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_transmitted] [decimal] (20, 8) NOT NULL,
[uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_manual_rcv] [decimal] (20, 8) NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NOT NULL CONSTRAINT [DF__tdc_inbou__date___47E601B0] DEFAULT (getdate()),
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_inbound_ASN_ins_tg]  ON [dbo].[tdc_inbound_ASN]
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
	@vendor_no		varchar(12),
	@uom			varchar(2),
	@po_uom			varchar(2),
	@base_uom		varchar(2),
	@qty_manul_rcvd		decimal(20, 8),
	@qty_transmitted	decimal(20, 8),
	@conv_factor		decimal(20, 8),
	@uom_voided_flag	char(1),
	@part_type		char(1),
	@po_status		char(1),
	@ASN_status		char(1),
	@ASN_status_transmitted	char(1),
	@err_found		char(1),
	@err_msg		varchar(255),
	@row_id			int

SELECT @ASN_status = CASE active WHEN 'Y' THEN 'H' ELSE 'A' END FROM tdc_config (NOLOCK) WHERE [function] = 'ASN_APPROVE_ACCEPT'

-- Cursor through each record 
DECLARE ASN_Cursor CURSOR FOR
	SELECT ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted, uom, status, row_id
	  FROM inserted

OPEN ASN_Cursor
FETCH NEXT FROM ASN_Cursor INTO @ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser,
		             	@qty_transmitted, @uom, @ASN_status_transmitted, @row_id

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Clear the temp variables
	SET @err_found	     = 'N'
	SET @err_msg	     = NULL
	SET @po_status	     = NULL
	SET @vendor_no 	     = NULL
	SET @part_type	     = NULL
	SET @uom_voided_flag = NULL
	SET @base_uom        = NULL
	SET @conv_factor     = 0
	SET @qty_manul_rcvd  = 0

	-- 1. Check that ASN is inserted
	IF @ASN IS NULL OR @ASN = ''
	BEGIN
		SET @err_msg   = 'ASN is required'
		SET @err_found = 'Y'
	END

	-- 2. Check that at least one of SSCC or carton_no is inserted
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
 
	-- 3. Check that if SSCC is inserted, it is 18 characters and it's unique
	IF @err_found = 'N'
	BEGIN
		IF @SSCC IS NOT NULL 
		BEGIN
			IF LEN(@SSCC) > 0 AND LEN(@SSCC) <> 18
			BEGIN
				SET @err_msg   = 'Invalid format SSCC'
				SET @err_found = 'Y'
			END

			IF @err_found = 'N'
			BEGIN
				IF EXISTS (SELECT * FROM tdc_inbound_ASN (NOLOCK) WHERE ASN != @ASN AND SSCC = @SSCC)
				BEGIN
					SET @err_msg   = 'SSCC must be unique'
					SET @err_found = 'Y'
				END
			END
		END
	END

	-- 4. Check that the inserted PO is a valid PO in the system
	IF @err_found = 'N'
	BEGIN
		SELECT @po_status = status,
		       @vendor_no = vendor_no
		  FROM purchase (NOLOCK) 
                 WHERE po_no = @po_no

		IF @po_status <> 'O'
		BEGIN
			SET @err_msg   = 'Invalid Purchase Number or Status'
			SET @err_found = 'Y'
		END
	END

	-- 5. Check that part_no or vend_part is inserted
	IF @err_found = 'N'
	BEGIN
		SET @part_no = @part_no

		IF @part_no IS NULL OR @part_no = ''
		BEGIN
			IF LEN(@vend_part) > 0
			BEGIN
				SELECT @part_no = (SELECT DISTINCT sku_no FROM vendor_sku WHERE vendor_no = @vendor_no AND vend_sku = @vend_part)
			END

			IF @part_no IS NULL OR @part_no = ''
			BEGIN
				SET @err_msg   = 'Part is required'
				SET @err_found = 'Y'
			END
		END
	END

	-- 6. Check that the part is on the PO
	IF @err_found = 'N'
	BEGIN
		SELECT @part_type = MAX(type),
		       @po_uom    = MAX(unit_measure)
		  FROM pur_list (NOLOCK) 
                 WHERE po_no      = @po_no 
                   AND part_no    = @part_no

		IF @part_type IS NULL OR @part_type = ''
		BEGIN
			SET @err_msg   = 'Part is not on the Purchase Order'
			SET @err_found = 'Y'
		END
	END

	-- 7. Check that uom is assigned to the part or pull it from the inv_master table
	IF @err_found = 'N'
	BEGIN
		IF @uom IS NULL OR @uom = ''
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

			SELECT @base_uom = @uom	
		END

		-- If the config flag is off, the entered uom cannot be different from the pur_list uom
		IF (SELECT active FROM tdc_config WHERE [function] = 'po_unit_of_measure') = 'N'
		AND @uom <> @po_uom
		BEGIN
			SET @err_msg   = 'UOM must match PO uom if config flag PO_UNIT_OF_MEASURE is not set'
			SET @err_found = 'Y'
		END

		IF @err_found = 'N'
		BEGIN
			-- Make sure that entered uom is a valid uom in the system
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
				IF @base_uom IS NULL
				BEGIN
					-- Get base uom
					IF @part_type = 'M'
					BEGIN
						SELECT @base_uom = @uom		
					END
					ELSE
					BEGIN
						SELECT @base_uom = uom FROM inv_master (NOLOCK) WHERE part_no = @part_no
					END
				END
	
				-- Make sure that the entered UOM and the base uom are the same category
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
	END

	-- 8. Get the conversion factor for the transmitted UOM
	IF @err_found = 'N'
	BEGIN
		IF @base_uom = @uom SET @conv_factor = 1

		IF @conv_factor = 0
		BEGIN
			SELECT @conv_factor = conv_factor				
	                  FROM uom_table (NOLOCK)		 
	 		 WHERE item    = @part_no
			   AND std_uom = @base_uom			 
	   		   AND alt_uom = @uom		 
		END

		IF @conv_factor = 0
		BEGIN
			SELECT @conv_factor = conv_factor				
	                  FROM uom_table (NOLOCK)		 
	 		 WHERE item    = 'STD'
			   AND std_uom = @base_uom			 
	   		   AND alt_uom = @uom	 
		END

		IF @conv_factor = 0
		BEGIN
			SET @err_msg   = 'Conversion Factor is not found'
			SET @err_found = 'Y'
		END
	END

	-- 9. Validate transmitted qty
	IF @err_found = 'N'
	BEGIN
		IF @qty_transmitted <= 0
		BEGIN
			SET @err_msg   = 'Quantity must be greater than 0'
			SET @err_found = 'Y'
		END

		-- Check that the base qty is not greater than qty left to receive
		IF (SELECT SUM(qty_ordered * conv_factor - qty_received * conv_factor)
                      FROM pur_list (NOLOCK) 
                     WHERE po_no   = @po_no 
                       AND part_no = @part_no) < @qty_transmitted * @conv_factor
		BEGIN
			SET @err_msg   = 'Transmitted quantity is greater than quantity left to receive'
			SET @err_found = 'Y'
		END
	END

	-- 10. Validate Lot
	IF @err_found = 'N'
	BEGIN
		-- Check that LOT is transmitted for Lot/Bin tracked part
		IF (SELECT lb_tracking FROM inv_master (NOLOCK) WHERE part_no = @part_no) = 'Y'	
		BEGIN
			-- Check that Lot is not transmitted for Fully serialized parts
			IF (SELECT serial_flag FROM inv_master (NOLOCK) WHERE part_no = @part_no) = 1
			BEGIN
				IF LEN(@lot_ser) > 0
				BEGIN
					SET @err_msg   = 'Lot should not be transmitted for Fully Serial Tracked items'
					SET @err_found = 'Y'
				END
			END

			IF @err_found = 'N'
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
		ELSE
		BEGIN
			IF LEN(@lot_ser) > 0
			BEGIN
				SET @err_msg   = 'Lot should not be transmitted for NOT Lot/Bin Tracked items'
				SET @err_found = 'Y'
			END
		END	
	END

	-- Reject the current record or update with new base_qty, base_uom ...
	IF @err_found = 'Y'
	BEGIN
		-- Reject the current record
		INSERT INTO tdc_inbound_ASN_err (ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted, uom, note, date_entered, err_msg)
		VALUES (@ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, @qty_transmitted, @uom, NULL, GETDATE(), @err_msg)

		-- Move all the accpted records into the error table
		INSERT INTO tdc_inbound_ASN_err(ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted, uom, note, date_entered, err_msg)
		SELECT ASN, SSCC, @GTIN, @EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted, uom, note, date_entered, NULL
		  FROM tdc_inbound_ASN
		 WHERE ASN     = @ASN
		   AND row_id != @row_id

		-- Move all the accpted ASN Serails records into the Serial error table
		INSERT INTO tdc_inbound_ASN_serial_err (ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no, date_entered, note)
		SELECT ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, serial_no, date_entered, 'Transmitting the ASN failed'
		  FROM tdc_inbound_ASN_serial
		 WHERE ASN  = @ASN

		DELETE FROM tdc_inbound_ASN        WHERE ASN = @ASN
		DELETE FROM tdc_inbound_ASN_serial WHERE ASN = @ASN
	END
	ELSE
	BEGIN	
		-- If at least one line of the ASN or ASN Serail has already been rejected, reject the rest of the ASN
		IF EXISTS (SELECT * FROM tdc_inbound_ASN_err        WHERE ASN = @ASN) OR
		   EXISTS (SELECT * FROM tdc_inbound_ASN_serial_err WHERE ASN = @ASN)
		BEGIN
			INSERT INTO tdc_inbound_ASN_err(ASN, SSCC, GTIN, EPC_TAG, carton_no, po_no, part_no, vend_part, lot_ser, qty_transmitted, uom, note, date_entered, err_msg)
			VALUES (@ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser, @qty_transmitted, @uom, NULL, GETDATE(), NULL)

			DELETE FROM tdc_inbound_ASN WHERE ASN = @ASN
		END
		ELSE
		BEGIN
			UPDATE tdc_inbound_ASN
			   SET part_no  = @part_no,
			       lot_ser  = @lot_ser,
			       status   = @ASN_status
			 WHERE row_id   = @row_id
		END
	END

	-- Clear the variables for the next record
	SET @ASN 	= NULL 	SET @SSCC	     = NULL
	SET @carton_no	= NULL 	SET @po_no	     = NULL 
	SET @part_no 	= NULL 	SET @vend_part       = NULL 
	SET @lot_ser	= NULL 	SET @lot_ser         = NULL
	SET @uom	= NULL	SET @qty_transmitted = NULL 
	SET @GTIN	= NULL	SET @ASN_status_transmitted = NULL
	SET @EPC_TAG	= NULL	

	FETCH NEXT FROM ASN_Cursor INTO @ASN, @SSCC, @GTIN, @EPC_TAG, @carton_no, @po_no, @part_no, @vend_part, @lot_ser,
			                @qty_transmitted, @uom, @ASN_status_transmitted, @row_id
END

CLOSE      ASN_Cursor
DEALLOCATE ASN_Cursor

RETURN
GO
ALTER TABLE [dbo].[tdc_inbound_ASN] ADD CONSTRAINT [CK_ASN_Status] CHECK (([status]='H' OR [status]='A'))
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_indx2] ON [dbo].[tdc_inbound_ASN] ([ASN], [carton_no], [po_no], [part_no], [lot_ser]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_indx4] ON [dbo].[tdc_inbound_ASN] ([ASN], [po_no], [part_no], [lot_ser]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_indx3] ON [dbo].[tdc_inbound_ASN] ([ASN], [SSCC], [carton_no], [po_no], [part_no], [lot_ser], [GTIN], [EPC_TAG]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_indx1] ON [dbo].[tdc_inbound_ASN] ([ASN], [SSCC], [po_no], [part_no], [lot_ser]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_indx5] ON [dbo].[tdc_inbound_ASN] ([row_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_indx6] ON [dbo].[tdc_inbound_ASN] ([status]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_inbound_ASN] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_inbound_ASN] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_inbound_ASN] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_inbound_ASN] TO [public]
GO
