SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************************************/
/* This procedure inserts all valid receipts from the temporary table #receipts */
/* into the real ADM table receipts, and lets the normal triggers take          */
/* over from there.                                                             */
/********************************************************************************/
CREATE PROCEDURE [dbo].[tdc_ins_receipt_ser_batch_asn]  @err_msg varchar(255) output
AS
 
DECLARE	@receipt_no int,
	@rdate datetime, 
	@part varchar(30),
	@line_no int,
	@po varchar(16),
	@po_key int,
	@loc varchar(10), 
	@qty decimal(20, 8),
	@err int,
	@tax_code varchar(10),	
	@conv_factor decimal(20, 8),
	@qc_flag char(1), 
	@order_no int,
	@ext int,
	@who varchar(50),
	@language varchar(10),
	@lot varchar(25),
	@bin varchar(12),
	@date_expires datetime,
	@cost decimal(20, 8),
	@tax decimal(20, 8),
--	@curr_key varchar(8),
--	@rate_type_home varchar(8),
--	@rate_type_oper varchar(8),
--	@juldate int,
	@sncounter int,
	@batch_no int
--	@uom char(2),

/* Find the first record */
SELECT @err = 0, @order_no = 0 

SELECT  @part = part_no, 
	@line_no = line_no, 
	@po = po_no, 
	@loc = location, 
	@qty = quantity, 
	@qc_flag = qc_flag,
	@bin = bin_no, 
	@who = who_entered, 
	@date_expires = date_expires
  FROM 	#receipts 
 WHERE 	row_id = 1

--SELECT @uom = uom FROM inv_master WHERE part_no = @part

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

IF (@bin IS NULL) OR (@date_expires IS NULL) 
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
		
/* Insert the record into receipts */
SELECT @rdate = min(release_date) 
  FROM releases (nolock) 
 WHERE po_no   = @po 
   AND part_no = @part 
   AND status  = 'O'
   AND po_line = @line_no

SELECT 	@cost = unit_cost, @tax_code = tax_code, @conv_factor = conv_factor
  FROM 	dbo.pur_list ( NOLOCK ) 
 WHERE 	po_no = @po 
   AND 	part_no = @part
   AND	line = @line_no

/* Make sure quantity equals number of serials */
SELECT @sncounter = count(*) FROM #asn_serial_no

IF (@qty <> @sncounter)
BEGIN             
	DECLARE @rec_qty varchar(20)

	-- Error: Received quantity %s must be positive.  THIS SHOULD BE CHANGED
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

--SELECT @curr_key = curr_key, @rate_type_home = rate_type_home, @rate_type_oper = rate_type_oper, @po_key = po_key
SELECT @po_key = po_key
  FROM purchase (nolock) 
 WHERE po_no = @po

--SELECT @juldate = DATEDIFF(D, '1901-01-01', getdate()) + 693961
--EXEC dbo.fs_curate_sp @juldate, @curr_key, @rate_type_home, @rate_type_oper

IF (@qc_flag <> 'Y') SET @sncounter = 1

BEGIN TRAN

	SELECT @batch_no = last_number + 1 FROM next_rec_batch_no
	UPDATE next_rec_batch_no SET last_number = last_number + 1

	/* Get the next receipt number */
	SELECT @receipt_no = last_no + 1 FROM next_rec_no
	UPDATE next_rec_no SET last_no = last_no + @sncounter

-- Removed in 736 logic is called from an eBO trigger now 
--	EXEC fs_calc_receipt_tax @po, @tax_code, @qty, @cost, @tax OUT

	DECLARE sn_cursor CURSOR FOR SELECT serial_no FROM #asn_serial_no ORDER BY serial_no
	OPEN sn_cursor
	FETCH NEXT FROM sn_cursor INTO @lot

	WHILE ( @@FETCH_STATUS = 0 )
	BEGIN
		INSERT INTO dbo.lot_bin_recv 
				( location, part_no, bin_no, lot_ser, tran_code, tran_no,    tran_ext, date_tran,  date_expires, qty,	direction, cost,	uom,		uom_qty,	conv_factor,	line_no,	who,	qc_flag, receipt_batch_no ) 
		 	SELECT 	 @loc,     @part,   @bin,   @lot,     'R',      @receipt_no, 0,        getdate(), @date_expires, 1, 	1, pur.unit_cost, pur.unit_measure, 1/pur.conv_factor, pur.conv_factor,	0,		@who,	@qc_flag, @batch_no 
			  FROM pur_list pur (nolock)
			 WHERE pur.po_no = @po 
			   AND pur.part_no = @part
			   AND pur.line = @line_no

		IF(@@ERROR != 0)
		BEGIN
			DEALLOCATE sn_cursor
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			RETURN -101
		END
		
		IF (@qc_flag = 'Y')
		BEGIN
	 		INSERT INTO dbo.receipts 
					( receipt_no,  po_no, part_no,   sku_no,    location, release_date, recv_date,      part_type, unit_cost, quantity, 		vendor,         unit_measure, prod_no, freight_cost,   status,   ext_cost, who_entered, conv_factor, bl_no, lb_tracking, freight_flag, freight_unit,    account_no,  po_key, qc_flag, over_flag, nat_curr,     std_util_dolrs,     std_ovhd_dolrs,     std_direct_dolrs,     std_cost,     oper_factor,     curr_factor,       oper_cost,      curr_cost, tax_included, po_line, receipt_batch_no ) 
			  	SELECT 	 @receipt_no, @po,   @part, list.vend_sku, @loc,     @rdate,        getdate(), list.type, list.unit_cost, 1/list.conv_factor, pur.vendor_no, list.unit_measure, 0,   pur.freight/list.conv_factor, 	'R', list.unit_cost/list.conv_factor, @who,    list.conv_factor, 0,    'Y', 	'N',          0.00000000, list.account_no, @po_key,    @qc_flag, 'N',   pur.curr_key, inv.std_util_dolrs, inv.std_ovhd_dolrs, inv.std_direct_dolrs, inv.std_cost, pur.oper_factor, pur.curr_factor, list.oper_cost, list.curr_cost, 0,@line_no, @batch_no
				  FROM purchase pur (nolock), pur_list list (nolock), inventory inv (nolock)
				 WHERE pur.po_no = list.po_no 
				   AND list.part_no = @part 
				   AND pur.po_no = @po
				   AND inv.location = @loc 
				   AND inv.part_no = @part
				   AND list.line = @line_no
			
			IF(@@ERROR != 0)
			BEGIN
				DEALLOCATE sn_cursor
				IF(@@TRANCOUNT > 0) ROLLBACK TRAN
				RETURN -101
			END

		--	SELECT @batch_no = @batch_no + 1
			SELECT @receipt_no = @receipt_no + 1
		END

		FETCH NEXT FROM sn_cursor INTO @lot
	END

	CLOSE sn_cursor

	IF (@qc_flag <> 'Y')
	BEGIN
 		INSERT INTO dbo.receipts 
				( receipt_no,  po_no, part_no,   sku_no,    location, release_date, recv_date,      part_type, unit_cost, quantity, 		vendor,         unit_measure, prod_no, freight_cost,   status,   ext_cost, who_entered, conv_factor, bl_no, lb_tracking, freight_flag, freight_unit,    account_no,  po_key, qc_flag, over_flag, nat_curr,     std_util_dolrs,     std_ovhd_dolrs,     std_direct_dolrs,     std_cost,     oper_factor,     curr_factor,       oper_cost,      curr_cost, tax_included, po_line, receipt_batch_no ) 
		  	SELECT 	 @receipt_no, @po,   @part, list.vend_sku, @loc,     @rdate,        getdate(), list.type, list.unit_cost, (@qty/list.conv_factor), pur.vendor_no, list.unit_measure, 0,   pur.freight/list.conv_factor, 'R', list.unit_cost/list.conv_factor, @who,    list.conv_factor, 0,    'Y', 	'N',          0.00000000, list.account_no, @po_key,    @qc_flag, 'N',   pur.curr_key, inv.std_util_dolrs, inv.std_ovhd_dolrs, inv.std_direct_dolrs, inv.std_cost, pur.oper_factor, pur.curr_factor, list.oper_cost, list.curr_cost, 0,@line_no, @batch_no
			  FROM purchase pur (nolock), pur_list list (nolock), inventory inv (nolock)
			 WHERE pur.po_no = list.po_no 
			   AND list.part_no = @part 
			   AND pur.po_no = @po
			   AND inv.location = @loc 
			   AND inv.part_no = @part
			   AND list.line = @line_no
		
		IF(@@ERROR != 0)
		BEGIN
			DEALLOCATE sn_cursor
			IF(@@TRANCOUNT > 0) ROLLBACK TRAN
			RETURN -101
		END
	END
	ELSE
	BEGIN
		-- last receipt number
		SELECT @receipt_no = @receipt_no - 1
	END	

	IF EXISTS (SELECT * FROM orders_auto_po (nolock) WHERE po_no = @po AND part_no = @part)
	BEGIN
		SELECT @order_no = MIN(order_no) FROM orders_auto_po (nolock) WHERE po_no = @po AND part_no = @part
		SELECT @ext = MAX(ext) FROM orders (nolock) WHERE order_no = @order_no AND type = 'I'

	--	IF OBJECT_ID('tempdb..#adm_taxinfo') IS NOT NULL
		TRUNCATE TABLE #adm_taxinfo

	--	IF OBJECT_ID('tempdb..#adm_taxtype') IS NOT NULL
		TRUNCATE TABLE #adm_taxtype

	--	IF OBJECT_ID('tempdb..#adm_taxtyperec') IS NOT NULL
		TRUNCATE TABLE #adm_taxtyperec

	--	IF OBJECT_ID('tempdb..#adm_taxcode') IS NOT NULL
		TRUNCATE TABLE #adm_taxcode

	--	IF OBJECT_ID('tempdb..#cents') IS NOT NULL
		TRUNCATE TABLE #cents

		EXEC fs_calculate_oetax @order_no, @ext, @err OUTPUT
		EXEC fs_updordtots @order_no, @ext

		OPEN sn_cursor
		FETCH NEXT FROM sn_cursor INTO @lot
	
		WHILE ( @@FETCH_STATUS = 0 )
		BEGIN
			EXEC @err = tdc_auto_drop_ship @po, 1, @lot, @bin, @who
	
			IF (@err < 0)
			BEGIN
				DEALLOCATE sn_cursor
				IF (@@TRANCOUNT > 0) ROLLBACK TRAN
	      			RETURN @err
			END

			FETCH NEXT FROM sn_cursor INTO @lot
		END		
	END

	DEALLOCATE sn_cursor

COMMIT TRAN

RETURN @receipt_no
GO
GRANT EXECUTE ON  [dbo].[tdc_ins_receipt_ser_batch_asn] TO [public]
GO
