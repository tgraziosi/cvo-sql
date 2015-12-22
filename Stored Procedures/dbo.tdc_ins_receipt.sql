SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************************************/
/* This procedure inserts all valid receipts from the temporary table #receipts */
/* into the real ADM table receipts, and lets the normal triggers take          */
/* over from there.                                                             */
/********************************************************************************/
-- v1.1 CT 13/06/2013 - Issue #695 - Logic fog receiving against a PO line which is ringfenced for Backorder processing

CREATE PROCEDURE [dbo].[tdc_ins_receipt] @err_msg varchar(255) output
AS
 
DECLARE	@receipt_no int, 
	@rdate datetime, 
	@misc_flag int,
	@part varchar(30),
	@line_no int,
	@po varchar(16), 
	@po_key int,
	@loc varchar(10), 
	@qty decimal(20, 8),
	@conv_factor decimal(20, 8),
	@err int,
	@tax_code varchar(10),	
	@price decimal(20, 8),
	@qc_flag char(1), 
	@order_no int,
	@ext int,
	@who varchar(50),
	@language varchar(10),
	@lot varchar(25),
	@bin varchar(12),
	@date_expires datetime,
	@lb_tracking char(1),
	@cost decimal(20, 8),
	@tax decimal(20, 8),
--	@curr_key varchar(8),
--	@rate_type_home varchar(8),
--	@rate_type_oper varchar(8),
--	@juldate int,
	@batch_no int,
	@pomask varchar(40)
	
	-- START v1.1
	DECLARE @releases_row_id	INT,
			@qty_to_allocate	DECIMAL(20,8),
			@qty_os				DECIMAL(20,8),
			@qty_applied		DECIMAL(20,8),
			@qty_received		DECIMAL(20,8),
			@qty_crossdock		DECIMAL(20,8),
			@rec_id				INT,
			@template_code		VARCHAR(30),
			@min_crossdock		DECIMAL(20,8),
			@location			VARCHAR(10),
			@bin_no				VARCHAR(12),
			@tran_id			INT,
			@new_tran_id		INT
	-- END v1.1

/* Find the first record */
SELECT @err = 0, @order_no = 0 
SELECT @misc_flag = 0, @err_msg = 'Error message not found.'

SELECT 	@part = part_no, 
	@line_no = line_no, 
	@po = po_no, 
	@loc = location, 
	@qty = quantity, 
	@qc_flag = qc_flag,
	@lot = lot_ser, 
	@bin = bin_no, 
	@who = who_entered, 
	@date_expires = date_expires
  FROM 	#receipts 
 WHERE 	row_id = 1

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @who), 'us_english')

SELECT @who = login_id FROM #temp_who

/* Make sure this PO number exists */
IF NOT EXISTS (SELECT * FROM purchase (nolock) WHERE po_no = @po AND status = 'O')
BEGIN
	-- Error: PO number %s is not valid.
        SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE module = 'SPR' 
	   AND trans = 'tdc_ins_receipt' 
	   AND err_no = -102 
	   AND language = @language

	--RAISERROR (@err_msg, 16, 1, @po)
	RETURN -102
END

IF NOT EXISTS (SELECT * FROM pur_list (nolock) WHERE part_no = @part AND po_no = @po AND line = @line_no)
BEGIN
	-- Error: Part number %s is not valid.
	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE module = 'SPR' 
	   AND trans = 'tdc_ins_receipt' 
	   AND err_no = -101 
	   AND language = @language

	--RAISERROR (@err_msg, 16, 1, @part)
	RETURN -101
END
        	
IF EXISTS (SELECT * FROM pur_list (nolock) WHERE po_no = @po AND part_no = @part AND line = @line_no AND type = 'M')
	SELECT @misc_flag = 1

/* Make sure quantity is positive */
IF (@qty <= 0.0)
BEGIN             
	DECLARE @rec_qty varchar(20)

	-- Error: Received quantity %s must be positive.
	SELECT @rec_qty = CONVERT(VARCHAR(20), @qty)

	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE module = 'SPR' 
	   AND trans = 'tdc_ins_receipt' 
	   AND err_no = -104 
	   AND language = @language

	--RAISERROR (@err_msg, 16, 1, @rec_qty)                  			 
	RETURN -104
END
    
SELECT @lb_tracking = ISNULL((SELECT lb_tracking FROM inv_master (nolock) WHERE part_no = @part), 'N')

IF (@lb_tracking = 'Y')
BEGIN
	IF (@lot IS NULL) OR (@bin IS NULL) OR (@date_expires IS NULL) 
	BEGIN
		-- Error: Lot-bin information required for item %s
		SELECT @err_msg = err_msg 
		  FROM tdc_lookup_error (nolock) 
		 WHERE module = 'SPR' 
		   AND trans = 'tdc_ins_receipt' 
		   AND err_no = -105 
		   AND language = @language

		--RAISERROR (@err_msg, 16, 1, @part)
		RETURN -105
	END                        
END

/* Insert the record into receipts */
SELECT @rdate = min(release_date),
		@releases_row_id = MIN(row_id) -- v1.1
  FROM releases (nolock) 
 WHERE po_no   = @po 
   AND part_no = @part 
   AND status  = 'O'
   AND po_line = @line_no

-- START v1.1 - check if this is ringfenced PO stock
SET @qty_to_allocate = @qty
SET @rec_id = 0

/*
-- Create temp table of backorders
CREATE TABLE #po_backorders (
	rec_id		INT,
	qty			DECIMAL(20,8),
	bin_no		VARCHAR(10),
	location	VARCHAR(10),
	crossdock	SMALLINT)
*/

-- Loop through ringfenced table and assign stock if required
WHILE 1=1
BEGIN
	SELECT TOP 1
		@rec_id = rec_id,
		@template_code = template_code,
		@qty_os = qty_ringfenced - (qty_received + qty_ready_to_process),
		@bin_no = bin_no
	FROM 
		dbo.CVO_backorder_processing_orders_po_xref (NOLOCK)
	WHERE
		[status] <= 0
		AND qty_ringfenced > (qty_received + qty_ready_to_process)
		AND rec_id > @rec_id
		AND releases_row_id = @releases_row_id
	ORDER BY
		rec_id


	IF @@ROWCOUNT = 0
		BREAK

	-- Get template details
	SELECT
		@location = location,
		@min_crossdock = min_crossdock
	FROM
		dbo.CVO_backorder_processing_templates (NOLOCK)
	WHERE
		template_code = @template_code

	-- Apply stock
	IF @qty_to_allocate > @qty_os 
	BEGIN
		SET @qty_applied = @qty_os
		SET @qty_to_allocate = @qty_to_allocate - @qty_applied
	END
	ELSE
	BEGIN
		SET @qty_applied = @qty_to_allocate
		SET @qty_to_allocate = 0
	END


	-- Write record
	INSERT INTO #po_backorders(
		rec_id,
		qty,
		bin_no,
		location,
		crossdock)
	SELECT
		@rec_id,
		@qty_applied,
		@bin_no,
		@location,
		CASE WHEN @qty_os >= ISNULL(@min_crossdock,0) THEN 1 ELSE 0 END
	
	IF @qty_to_allocate <= 0
		BREAK

END

IF NOT EXISTS (SELECT 1 FROM #po_backorders) 
BEGIN
	DROP TABLE #po_backorders
END
ELSE
BEGIN
	-- If there are any POs which need to go to a crossdock bin then get the bin
	IF EXISTS (SELECT 1 FROM #po_backorders WHERE crossdock = 1) 
	BEGIN
		-- Is there already a crossdock bin for this part
		SELECT TOP 1
			@bin_no = a.bin_no
		FROM
			dbo.lot_bin_stock a (NOLOCK)
		INNER JOIN
			dbo.tdc_bin_master b (NOLOCK)
		ON
			a.bin_no = b.bin_no
			AND a.location = b.location
		WHERE
			a.location = @location
			AND a.part_no = @part
			AND b.group_code = 'CROSSDOCK'
			AND b.status = 'A'

		-- If no bin then get the crossdock bin with the least stock in it
		IF @bin_no IS NULL
		BEGIN
			SELECT TOP 1
				@bin_no = a.bin_no
			FROM
				dbo.tdc_bin_master a (NOLOCK)
			LEFT JOIN
				(SELECT location, bin_no, SUM(qty) qty FROM dbo.lot_bin_stock (NOLOCK) GROUP BY location, bin_no) b
			ON
				a.bin_no = b.bin_no
				AND a.location = b.location
			WHERE
				a.location = @location
				AND a.group_code = 'CROSSDOCK'
				AND a.status = 'A'
			ORDER BY 
				ISNULL(b.qty,0) 
		END
			
		IF @bin_no IS NOT NULL
		BEGIN
			UPDATE
				#po_backorders
			SET
				bin_no = ISNULL(bin_no,@bin_no)
			WHERE
				crossdock = 1
		END	
	END
END
-- END v1.1



SELECT @cost = unit_cost, @tax_code = tax_code, @conv_factor = conv_factor 
  FROM dbo.pur_list ( NOLOCK ) 
 WHERE po_no = @po 
   AND part_no = @part
   AND line = @line_no

--SELECT @curr_key = curr_key, @rate_type_home = rate_type_home, @rate_type_oper = rate_type_oper, @po_key = po_key
SELECT @po_key = po_key
  FROM purchase (nolock) 
 WHERE po_no = @po

--SELECT @juldate = DATEDIFF(D, '1901-01-01', getdate()) + 693961
--EXEC dbo.fs_curate_sp @juldate, @curr_key, @rate_type_home, @rate_type_oper

BEGIN TRAN

	UPDATE next_rec_batch_no SET last_number = last_number + 1 
	SELECT @batch_no = last_number FROM next_rec_batch_no

	/* Get the next receipt number */
	SELECT @receipt_no = last_no + 1 FROM next_rec_no
	UPDATE next_rec_no SET last_no = @receipt_no

--	IF (@lb_tracking = 'Y')
--	BEGIN
--		EXEC fs_calc_receipt_tax @po, @tax_code, 0, @cost, @tax OUT
--	END

-- Removed in 736 logic is called from an eBO trigger now 
--	EXEC fs_calc_receipt_tax @po, @tax_code, @qty, @cost, @tax OUT

	IF (@lb_tracking = 'Y')
	BEGIN
		INSERT INTO dbo.lot_bin_recv 
				( location, part_no, bin_no, lot_ser, tran_code, tran_no,    tran_ext, date_tran,  date_expires,  qty,                   direction, cost,          uom,           uom_qty, conv_factor, line_no, who,  qc_flag, receipt_batch_no ) 
		 	SELECT 	 @loc,     @part,   @bin,   @lot,     'R',      @receipt_no, 0,        getdate(), @date_expires, @qty * pur.conv_factor, 1,     pur.unit_cost, pur.unit_measure, @qty, pur.conv_factor, 0, 	@who, @qc_flag, @batch_no 
			  FROM pur_list pur (nolock)
			 WHERE pur.po_no = @po 
			   AND pur.part_no = @part
			   AND pur.line = @line_no

		IF(@@ERROR != 0)
		BEGIN
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			RETURN -101
		END
	END
	
	IF (@misc_flag = 1) -- miscellaneous part
	BEGIN
 		INSERT INTO dbo.receipts 
				( receipt_no,  po_no, part_no,   sku_no,    location, release_date, recv_date,      part_type, unit_cost,  quantity, vendor,         unit_measure, prod_no, freight_cost,   status,   ext_cost,  	who_entered, conv_factor, bl_no, lb_tracking, freight_flag, freight_unit,    account_no,  po_key, qc_flag, over_flag, nat_curr, std_util_dolrs, std_ovhd_dolrs, std_direct_dolrs, std_cost, oper_factor,     curr_factor,      oper_cost,         		  curr_cost, tax_included, po_line, receipt_batch_no ) 
		  	SELECT 	 @receipt_no, @po,   @part, list.vend_sku, @loc,     @rdate,        getdate(), list.type, list.curr_cost, @qty,  pur.vendor_no, list.unit_measure, pur.prod_no,   pur.freight * @qty, 'R', list.curr_cost * @qty, @who,    list.conv_factor, 0,     'N', 	       'N',          0.00000000, list.account_no, @po_key,    @qc_flag, 'N',   pur.curr_key, 0,              0,              0,                0,    pur.oper_factor, pur.curr_factor, list.oper_cost, list.curr_cost, 0, @line_no, @batch_no
			  FROM purchase pur (nolock), pur_list list (nolock)
			 WHERE pur.po_no = list.po_no 
			   AND pur.po_no = @po 
			   AND list.part_no = @part
			   AND list.line = @line_no
	END
	ELSE
	BEGIN
 		INSERT INTO dbo.receipts 
				( receipt_no,  po_no, part_no,   sku_no,    location, release_date, recv_date,      part_type, unit_cost,  quantity, vendor,         unit_measure, prod_no, freight_cost,   status,   ext_cost,  who_entered, conv_factor, bl_no, lb_tracking, freight_flag, freight_unit,    account_no,  po_key, qc_flag, over_flag, nat_curr,     std_util_dolrs,     std_ovhd_dolrs,     std_direct_dolrs,     std_cost,     oper_factor,     curr_factor,       oper_cost,      curr_cost, tax_included, po_line, receipt_batch_no ) 
		  	SELECT 	 @receipt_no, @po,   @part, list.vend_sku, @loc,     @rdate,        getdate(), list.type, list.unit_cost, @qty,  pur.vendor_no, list.unit_measure, pur.prod_no,   pur.freight * @qty, 'R', list.unit_cost * @qty, @who,    list.conv_factor, 0,    @lb_tracking, 'N',          0.00000000, list.account_no, @po_key,    @qc_flag, 'N',   pur.curr_key, inv.std_util_dolrs, inv.std_ovhd_dolrs, inv.std_direct_dolrs, inv.std_cost, pur.oper_factor, pur.curr_factor, list.oper_cost, list.curr_cost, 0, @line_no, @batch_no
			  FROM purchase pur (nolock), pur_list list (nolock), inventory inv (nolock)
			 WHERE pur.po_no = list.po_no 
			   AND list.part_no = @part 
			   AND pur.po_no = @po
			   AND inv.location = @loc 
			   AND inv.part_no = @part
			   AND list.line = @line_no
	END

	IF(@@ERROR != 0)
	BEGIN
		IF(@@TRANCOUNT > 0) ROLLBACK TRAN
		RETURN -101
	END

	IF EXISTS (SELECT * FROM orders_auto_po (nolock) WHERE po_no = @po AND part_no = @part)
	BEGIN
		EXEC @err = tdc_auto_drop_ship @po, @qty, @lot, @bin, @who

		IF (@err < 0)
		BEGIN
			IF (@@TRANCOUNT > 0) ROLLBACK TRAN
      			RETURN @err
		END
	END
/*
	-- START v1.1 - Ringfenced Backorder Processing PO stock 
	IF OBJECT_ID('tempdb..#po_backorders') IS NOT NULL
	BEGIN
		
		-- Get qty to crossdock
		SELECT
			@qty_crossdock = SUM(qty),
			@bin_no = MIN(bin_no)
		FROM
			#po_backorders
		WHERE
			crossdock = 1

		IF ISNULL(@qty_crossdock,0) > 0
		BEGIN

			-- Get put queue record
			SELECT 
				@tran_id = tran_id,
				@qty_received = qty_to_process
			FROM
				dbo.tdc_put_queue (NOLOCK) 
			WHERE 
				part_no = @part 
				AND tran_receipt_no = @receipt_no 
				AND trans = 'POPTWY'		

			-- If no put queue record then this must have gone to a non-receipt bin
			IF @tran_id IS NULL
			BEGIN
				SET @qty_received = @qty
			END
			
			-- If the full amount is being moved to crossdock then update the put queue record
			IF @qty_crossdock = @qty_received
			BEGIN
				IF @tran_id IS NOT NULL
				BEGIN
					UPDATE tdc_put_queue SET next_op = @bin_no WHERE tran_id = @tran_id
				END
				ELSE
				BEGIN
					-- Create a new put queue record
					EXEC dbo.cvo_create_poptwy_transaction_sp @location, @po,	@receipt_no, @part,	'1', @bin, @bin_no, @qty_crossdock, @who, @new_tran_id OUTPUT
				END

			END
			ELSE
			BEGIN
				-- Split the ringfence qty from the rest
				-- 1. Update existing transaction
				IF @tran_id IS NOT NULL
				BEGIN
					UPDATE tdc_put_queue SET qty_to_process = qty_to_process - @qty_crossdock WHERE tran_id = @tran_id
				END

				-- Create a new put queue record
				EXEC dbo.cvo_create_poptwy_transaction_sp @location, @po,	@receipt_no, @part,	'1', @bin, @bin_no, @qty_crossdock, @who, @new_tran_id OUTPUT
				
			END
		END

		-- Update cross reference table
		UPDATE
			a
		SET
			qty_received = a.qty_received + b.qty,
			bin_no = CASE b.crossdock WHEN 1 THEN b.bin_no ELSE NULL END
		FROM
			dbo.CVO_backorder_processing_orders_po_xref a
		INNER JOIN
			#po_backorders b
		ON
			a.rec_id = b.rec_id
	END
	-- END v1.1
*/


IF (@@TRANCOUNT > 0) COMMIT TRAN

RETURN @receipt_no
GO
GRANT EXECUTE ON  [dbo].[tdc_ins_receipt] TO [public]
GO
