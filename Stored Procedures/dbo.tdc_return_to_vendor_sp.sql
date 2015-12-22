SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_return_to_vendor_sp]
AS

/* This stored procedure try to close a return to vendor number (either pcs or not pcs) */

DECLARE @rtv_no int, @line int, @row_id int, @child int, @match int
DECLARE @loc varchar(10), @part varchar(30), @lot varchar(25), @bin varchar(12), @po_ctrl_num varchar(10), @vendor_invoice_no varchar(20)
DECLARE @lb_track char(1), @status char(1), @pcs char(1), @err int, @account varchar(32)
DECLARE @qty decimal(20,8), @ordered decimal(20,8), @sum_qty decimal(20,8), @amt_net decimal(20,8)
DECLARE @stock decimal(20,8), @avail_qty decimal(20,8)
DECLARE @language varchar(10), @msg varchar(255), @part_type char(1)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

--Call 1103241PSC Jim 08/07/2008  SCR#050696
declare @curr_date int, @period_end_date int

SELECT @curr_date = datediff(day,'01/01/1900',getdate()) + 693596

SELECT @period_end_date = CASE WHEN ISNUMERIC(value_str)=1 THEN 
		CAST(value_str AS INT) 
		ELSE 0 END 
  FROM config (NOLOCK) 
 WHERE upper(flag) = 'DIST_PLT_END_DATE' 

if @curr_date > @period_end_date				-- mls 8/19/03 SCR 31660 start
begin
	select @msg = 'Cannot apply transaction to ' + convert(varchar(10),getdate(),101) + ' because it is in a future period.'
	RAISERROR (@msg, 16, 1)
	RETURN -102
end
--Call 1103241PSC Jim 08/07/2008

-- if pcs is on we can have multiple child id for the same line number
SELECT @row_id = (SELECT COUNT(DISTINCT line_no) FROM #return_to_vendor)

IF(@row_id = 0)
BEGIN
--	UPDATE #return_to_vendor SET err_msg = 'No record in temp table #return_to_vendor'
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -101 AND language = @language
	RAISERROR (@msg, 16, 1)
	RETURN -101
END

SELECT @rtv_no = (SELECT DISTINCT rtv_no FROM #return_to_vendor)
SELECT @po_ctrl_num = (SELECT 'R' + CONVERT(char(8), @rtv_no))

-- all part number for a return vendor number must be entered at the same time
IF((SELECT COUNT(*) FROM rtv_list (nolock) WHERE rtv_no = @rtv_no) <> @row_id)
BEGIN
--	UPDATE #return_to_vendor SET err_msg = 'Some part number is missing'
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -102 AND language = @language
	RAISERROR (@msg, 16, 1)
	RETURN -102
END

SELECT @loc = location, @status = status FROM rtv (nolock) WHERE rtv_no = @rtv_no

IF(@status = 'V') OR (@status = 'S')
BEGIN
--	UPDATE #return_to_vendor SET err_msg = 'This RTV number is closed/void'
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -103 AND language = @language
	RAISERROR (@msg, 16, 1)
	RETURN -103
END

IF(@status != 'N')
BEGIN
--	UPDATE #return_to_vendor SET err_msg = 'Invalid RTV number'
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -104 AND language = @language
	RAISERROR (@msg, 16, 1)
	RETURN -104
END

IF EXISTS ( SELECT *
	      FROM lot_bin_stock s (nolock), rtv_list r (nolock) 
	     WHERE s.part_no = r.part_no 
	       AND s.location = r.location 
	       AND s.lot_ser = r.lot_ser 
	       AND s.bin_no = r.bin_no 
	       AND s.qty < r.qty_ordered * r.conv_factor 
	       AND r.rtv_no = @rtv_no 
	       AND r.lb_tracking = 'Y' )
OR
EXISTS ( SELECT * 
	   FROM inventory s (nolock), rtv_list r (nolock) 
	  WHERE s.part_no = r.part_no 
	    AND s.location = r.location 
	    AND s.in_stock < r.qty_ordered * r.conv_factor 
	    AND r.rtv_no = @rtv_no
	    AND r.type <> 'M'
	    AND r.lb_tracking = 'N' )
BEGIN			
	-- Error: There is not enough of item in stock
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -111 AND language = @language
	RAISERROR (@msg, 16, 1)
	RETURN -111
END

-- get value for pcs flag
SELECT @pcs = (SELECT DISTINCT pcs FROM #return_to_vendor)

BEGIN TRAN

SELECT @account = account FROM issue_code WHERE code ='RTV'

UPDATE rtv SET status = 'S', post_to_ap = 'Y' WHERE rtv_no = @rtv_no AND status = 'N' 

EXEC dbo.glactref_sp @account

UPDATE adm_next_match_no SET last_no = last_no + 1
SELECT @match = (SELECT max(last_no) FROM adm_next_match_no)

DECLARE return_2_vendor CURSOR FOR
	SELECT child_no, line_no, part_no, lot_ser, bin_no, quantity FROM #return_to_vendor 

OPEN return_2_vendor
FETCH NEXT FROM return_2_vendor INTO @child, @line, @part, @lot, @bin, @qty

WHILE (@@FETCH_STATUS = 0)
BEGIN
	IF NOT EXISTS (SELECT * FROM rtv_list (nolock) WHERE rtv_no = @rtv_no AND part_no = @part)
	BEGIN
		DEALLOCATE return_2_vendor
		ROLLBACK TRAN
	--	UPDATE #return_to_vendor SET err_msg = 'Invalid part number %s.'
		SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -105 AND language = @language
		RAISERROR (@msg, 16, 1, @part)
		RETURN -105
	END

	IF (@pcs = 'Y')
	BEGIN
		IF NOT EXISTS (SELECT * FROM tdc_pcs_item (nolock) WHERE child_serial_no = @child AND location = @loc)
		BEGIN
			DEALLOCATE return_2_vendor
			ROLLBACK TRAN
		--	UPDATE #return_to_vendor SET err_msg = PCSN does not exist at location %s.
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -106 AND language = @language
			RAISERROR (@msg, 16, 1, @loc)
			RETURN -106
		END

		IF NOT EXISTS (SELECT * FROM tdc_pcs_item (nolock) WHERE child_serial_no = @child AND location = @loc AND part_no = @part)
		BEGIN
			DEALLOCATE return_2_vendor
			ROLLBACK TRAN
		--	UPDATE #return_to_vendor SET err_msg = 'Part number %s does not exist on PCSN %d.
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -107 AND language = @language
			RAISERROR (@msg, 16, 1, @part, @child)
			RETURN -107
		END
	END

	IF NOT EXISTS (SELECT * FROM rtv_list (nolock) WHERE rtv_no = @rtv_no AND part_no = @part AND line_no = @line)
	BEGIN
		DEALLOCATE return_2_vendor
		ROLLBACK TRAN
	--	UPDATE #return_to_vendor SET err_msg = 'Part number %s does not match the line number %d.'
		SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -108 AND language = @language
		RAISERROR (@msg, 16, 1, @part, @line)
		RETURN -108
	END

	SELECT @ordered = 0, @sum_qty = 0

	SELECT @ordered = qty_ordered, @part_type = type, @lb_track = lb_tracking
	  FROM rtv_list (nolock) 
	 WHERE rtv_no = @rtv_no AND line_no = @line

	SELECT @sum_qty = (SELECT sum(quantity) FROM #return_to_vendor WHERE line_no = @line)

	IF(@ordered <> @sum_qty)
	BEGIN
		DEALLOCATE return_2_vendor
		ROLLBACK TRAN
	--	UPDATE #return_to_vendor SET err_msg = 'Given quantity is not equal to ordered quantity'
		SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -109 AND language = @language
		RAISERROR (@msg, 16, 1)
		RETURN -109
	END

--	SELECT @lb_track = lb_tracking FROM inv_master (nolock) WHERE part_no = @part
	SELECT @avail_qty = 0, @stock = 0

	IF(@lb_track = 'Y')
	BEGIN
		IF NOT EXISTS (SELECT * FROM rtv_list (nolock) WHERE rtv_no = @rtv_no AND line_no = @line AND lot_ser = @lot AND bin_no = @bin)
		BEGIN
			DEALLOCATE return_2_vendor
			ROLLBACK TRAN
		--	UPDATE #return_to_vendor SET err_msg = 'Invalid lot/bin information'
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -110 AND language = @language
			RAISERROR (@msg, 16, 1)
			RETURN -110
		END

		IF (@pcs = 'Y')
		BEGIN
			IF NOT EXISTS (SELECT * FROM tdc_pcs_item (nolock) WHERE child_serial_no = @child AND location = @loc AND part_no = @part AND lot_ser = @lot AND bin_no = @bin)
			BEGIN
				DEALLOCATE return_2_vendor
				ROLLBACK TRAN
			--	UPDATE #return_to_vendor SET err_msg = 'Invalid lot/bin information for the given PCSN'
				SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -112 AND language = @language
				RAISERROR (@msg, 16, 1)
				RETURN -112
			END
		
			SELECT @avail_qty = (SELECT quantity FROM tdc_pcs_item (nolock)
						WHERE child_serial_no = @child AND location = @loc 
						AND part_no = @part AND lot_ser = @lot AND bin_no = @bin)
			IF(@avail_qty < @qty)
			BEGIN
				DEALLOCATE return_2_vendor
				ROLLBACK TRAN
			--	UPDATE #return_to_vendor SET err_msg = 'There is not enough of quantity under the given PCSN'
				SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -113 AND language = @language
				RAISERROR (@msg, 16, 1)
				RETURN -113
			END

			IF(@avail_qty = @qty)
			BEGIN
				DELETE FROM tdc_pcs_item 
				WHERE child_serial_no = @child AND part_no = @part AND location = @loc
				AND lot_ser = @lot AND bin_no = @bin

				IF NOT EXISTS (SELECT count(*) FROM tdc_pcs_item (nolock) WHERE child_serial_no = @child)
					DELETE FROM tdc_pcs_group WHERE child_serial_no = @child
			END
			ELSE
			BEGIN
				UPDATE tdc_pcs_item 
				SET quantity = quantity - @qty 
				WHERE child_serial_no = @child AND part_no = @part AND location = @loc
				AND lot_ser = @lot AND bin_no = @bin 
			END
		END
	END
	ELSE
	BEGIN
		IF (@pcs = 'Y')
		BEGIN
			SELECT @avail_qty = (SELECT quantity FROM tdc_pcs_item
						WHERE child_serial_no = @child AND location = @loc AND part_no = @part)
			IF(@avail_qty < @qty)
			BEGIN
				DEALLOCATE return_2_vendor
				ROLLBACK TRAN
			--	UPDATE #return_to_vendor SET err_msg = 'There is not enough of quantity under the given PCSN'
				SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_return_to_vendor_sp' AND err_no = -113 AND language = @language
				RAISERROR (@msg, 16, 1)
				RETURN -113
			END

			IF(@avail_qty = @qty)
			BEGIN
				DELETE FROM tdc_pcs_item WHERE child_serial_no = @child AND part_no = @part AND location = @loc 

				IF NOT EXISTS (SELECT count(*) FROM tdc_pcs_item (nolock) WHERE child_serial_no = @child) 
					DELETE FROM tdc_pcs_group WHERE child_serial_no = @child
			END
			ELSE
			BEGIN
				UPDATE tdc_pcs_item 
				SET quantity = quantity - @qty 
				WHERE child_serial_no = @child AND part_no = @part AND location = @loc
			END
		END
	END

	IF(@part_type = 'M')
	BEGIN
		UPDATE rtv_list 
		   SET status = 'S', post_to_ap = 'Y' 
		 WHERE rtv_no = @rtv_no 
		   AND line_no = @line 
		   AND status = 'N'
	END
	ELSE
	BEGIN
		UPDATE rtv_list 
		   SET account_no = @account, status = 'S', post_to_ap = 'Y' 
		 WHERE rtv_no = @rtv_no
		   AND line_no = @line 
		   AND status = 'N'
	END

	-- Call 312247MPS (reference_code)  07/10/08
	IF NOT EXISTS (SELECT * FROM adm_pomchcdt (nolock) WHERE po_ctrl_num = @po_ctrl_num AND match_line_num = @line)
	BEGIN		
		INSERT INTO adm_pomchcdt ( match_ctrl_int, match_line_num, po_ctrl_num,  po_ctrl_int, po_line_num, gl_acct,             qty_ordered, unit_price,         match_unit_price,   qty_invoiced, match_posted_flag, part_no, item_desc,            gl_ref_code, tax_code,          amt_tax, amt_tax_included, calc_tax, conv_factor,  receipt_no, location,          project1, project2, project3, nat_curr,     oper_factor, curr_factor, oper_cost,          curr_cost,          misc ) 
		SELECT                     @match,         @line,          @po_ctrl_num, @rtv_no,     0,           rtv_list.account_no, @qty,        rtv_list.unit_cost, rtv_list.unit_cost, @qty,         -1, 		      @part,   substring(rtv_list.[description], 1, 60), rtv_list.reference_code,        rtv_list.tax_code, 0.0,     rtv.tax_amt,      0.0,      rtv_list.conv_factor, 0,          rtv_list.location, '',       '',       '',       rtv.currency_key, rtv.oper_factor, 	null,        rtv_list.oper_cost, rtv_list.curr_cost, 'N' 
		FROM rtv, rtv_list  WHERE rtv_list.rtv_no = @rtv_no AND rtv_list.line_no = @line AND rtv.rtv_no = @rtv_no
	END

	FETCH NEXT FROM return_2_vendor INTO @child, @line, @part, @lot, @bin, @qty
END

DEALLOCATE return_2_vendor

SELECT @vendor_invoice_no = (SELECT ISNULL(vend_rma_no, 'rma') FROM rtv WHERE rtv_no = @rtv_no)
SELECT @amt_net = (SELECT (total_amt_order - restock_fee - freight + tax_amt) FROM rtv WHERE rtv_no = @rtv_no)

INSERT INTO adm_pomchchg ( match_ctrl_int, vendor_code,   vendor_remit_to, printed_flag, amt_net,  amt_discount, amt_tax,     amt_freight,  amt_misc,         amt_due,  match_posted_flag, nat_cur_code,     amt_tax_included, apply_date,     aging_date,         due_date,           discount_date, invoice_receive_date, vendor_invoice_date, vendor_invoice_no,  date_match, amt_gross,           location,     rate_type_home, 	rate_type_oper,     curr_factor,     oper_factor,     trx_type, tax_code, terms_code ) 
SELECT 			   @match,         rtv.vendor_no, '',              0,            @amt_net, 0.0,          rtv.tax_amt, rtv.freight,  -rtv.restock_fee, @amt_net, 0,                 rtv.currency_key, rtv.tax_amt,      rtv.apply_date, rtv.date_of_order,  rtv.date_order_due, getdate(),     getdate(),            getdate(),           @vendor_invoice_no, getdate(),  rtv.total_amt_order, rtv.location, rtv.rate_type_home, rtv.rate_type_oper, rtv.curr_factor, rtv.oper_factor, 4092,	rtv.tax_code, rtv.terms
FROM rtv WHERE rtv_no = @rtv_no
 
UPDATE rtv 
   SET match_ctrl_int = @match 
 WHERE rtv_no = @rtv_no

EXEC dbo.fs_calculate_matchtax_wrap @match, 3 -- SCR38430

UPDATE adm_pomchcdt 
   SET match_posted_flag = 0 
 WHERE match_ctrl_int = @match

IF (@err < 0)
BEGIN
	ROLLBACK TRAN
	-- Error: Tax calculation failed
	UPDATE #return_to_vendor SET err_msg = 'Tax calculation failed'
	RETURN -114
END

IF @@TRANCOUNT > 0
	COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_return_to_vendor_sp] TO [public]
GO
