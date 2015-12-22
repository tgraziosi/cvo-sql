SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[appoxhdr_sp] 	@company_id		int,
				@post_lock		int,
				@today			int,
				@smuser_id		int
AS
DECLARE @terms_code	varchar(8), 
	@date_doc	int, 
	@date_due	int,
	@loop_rec_id	int,
	@max_rec_id	int,
	@min_rec_id	int,
	@last_ctrl_num	float,
	@ctrl_num_mask	varchar(16),
	@int_holder	int,
	@num_len	int,
	@date_discount  int,
	@app_error_flag	int,
	@po_ctrl_num	varchar(16),
	@po_ctrl_num_tot	varchar(16),
	@match_ctrl_num		varchar(16)




CREATE TABLE  #get_missing_dates  (
	rec_id			int,
	terms_code		varchar(8),
	date_doc		int,
	date_due		int,
	date_discount		int
)



CREATE TABLE #rounded_extended
(match_ctrl_num varchar(16),
amt_extended float)

INSERT #rounded_extended
(match_ctrl_num,
amt_extended)
SELECT dtl.match_ctrl_num,
      round((dtl.invoice_unit_price * dtl.qty_invoiced ), isnull(g.curr_precision,1.0)) 
FROM  epmchhdr hdr LEFT OUTER JOIN glcurr_vw g (nolock) ON (hdr.nat_cur_code = g.currency_code), epmchdtl dtl 
WHERE hdr.match_posted_flag = @post_lock
AND   hdr.match_ctrl_num = dtl.match_ctrl_num

SELECT 	hdr.match_ctrl_num, sum(dtl.amt_extended) AS amt_total, hdr.amt_tax_included, hdr.nat_cur_code
INTO 	#match_extended
FROM 	epmchhdr hdr , #rounded_extended dtl
WHERE	hdr.match_posted_flag = @post_lock
AND	hdr.match_ctrl_num = dtl.match_ctrl_num
GROUP BY hdr.match_ctrl_num, hdr.amt_tax_included, hdr.nat_cur_code

SELECT match_ctrl_num, (amt_total - amt_tax_included) AS amt_gross
INTO #match_totals
FROM #match_extended



	
	INSERT #apinpchg(
		match_ctrl_num,
		trx_ctrl_num,
		trx_type,
		doc_ctrl_num,
		apply_to_num,
		user_trx_type_code,
		batch_code,
		po_ctrl_num,
		vend_order_num,
		ticket_num,
		date_applied,
		date_aging,
		date_due,
		date_doc,
		date_entered,
		date_received,
		date_required,
		date_recurring,
		date_discount,
		posting_code,
		vendor_code,
		pay_to_code,
		branch_code,
		class_code,
		approval_code,
		comment_code,
		fob_code,
		terms_code,
		tax_code,
		recurring_code,
		location_code,
		payment_code,
		times_accrued,
		accrual_flag,
		drop_ship_flag,
		posted_flag,
		hold_flag,
		add_cost_flag,
		approval_flag,
		recurring_flag,
		one_time_vend_flag,
		one_check_flag,
		amt_gross,
		amt_discount,
		amt_tax,
		amt_freight,
		amt_misc,
		amt_net,
		amt_paid,
		amt_due,
		amt_restock,
		amt_tax_included,
		frt_calc_tax,
		doc_desc,
		hold_desc,
		user_id,
		next_serial_id,
		pay_to_addr1,
		pay_to_addr2,
		pay_to_addr3,
		pay_to_addr4,
		pay_to_addr5,
		pay_to_addr6,
		attention_name,
		attention_phone,
		intercompany_flag,
		company_code,
		cms_flag,
		process_group_num,
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		net_original_amt,
		org_id,
		tax_freight_no_recoverable			
		)
	SELECT  DISTINCT a.match_ctrl_num,
		' ',
		4091,
		a.vendor_invoice_no,
		' ',
		d.user_trx_type_code,
		a.batch_code,
		a.match_ctrl_num,
		'',
		'',
		a.apply_date,
		a.aging_date,
		a.due_date,
		a.vendor_invoice_date,
		@today,
		a.invoice_receive_date,
		a.invoice_receive_date,
		0,
		a.discount_date,
		d.posting_code,
		a.vendor_code,
		vendor_remit_to = CASE ISNULL(a.vendor_remit_to, ' ')
					WHEN '' THEN ' '
					ELSE a.vendor_remit_to
				END,
		d.branch_code,
		d.vend_class_code,
		c.default_aprv_code,
		d.comment_code,
		d.fob_code,
		d.terms_code,
		d.tax_code,
		' ',
		d.location_code,
		d.payment_code,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		one_time_vend_flag = CASE d.vendor_code
					WHEN c.one_time_vend_code THEN 1
					ELSE 0
				END,
		0,
		f.amt_gross,
		a.amt_discount,
		a.amt_tax,
		a.amt_freight,
		a.amt_misc,
		((f.amt_gross + a.amt_freight + a.amt_misc +  a.amt_tax) - a.amt_discount),
		0.0,
		((f.amt_gross + a.amt_freight + a.amt_misc +  a.amt_tax) - a.amt_discount),
		0.0,
		a.amt_tax_included,
		0.0,
		'',
		'',
		@smuser_id,
		0,
		'',
		'',
		'',
		'',
		'',
		'',
		d.attention_name,
		d.attention_phone,
		intercompany_flag = CASE (SELECT COUNT(*) FROM epmchdtl 
						WHERE company_id <> @company_id 
						AND match_ctrl_num = a.match_ctrl_num)
					WHEN 0 THEN 0
					ELSE 1
				END,
		e.company_code,
		0,
		'',
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		((f.amt_gross + a.amt_freight + a.amt_misc +  a.amt_tax) - a.amt_discount),
	 	CASE WHEN LEN(LTRIM(RTRIM(ISNULL(a.org_id,'')))) = 0 		
			THEN				
				(SELECT default_matching_organization FROM epmchopt WHERE company_id = e.company_id )
			ELSE
				a.org_id
			END,
		0		
	FROM epmchhdr a, apco c, apvend d, glcomp_vw e, #match_totals f
	WHERE  a.vendor_code = d.vendor_code
	AND c.company_id = e.company_id
	AND a.match_posted_flag = @post_lock
	AND a.match_ctrl_num = f.match_ctrl_num

	SELECT @match_ctrl_num = Min(match_ctrl_num)
	FROM #apinpchg




























	


	IF @@error != 0  
	BEGIN 
		RETURN 100
	END 

	
	update #apinpchg
		set pay_to_addr1 = ISNULL(addr1, ''),
			pay_to_addr2 = ISNULL(b.addr2, ''),
			pay_to_addr3 = ISNULL(b.addr3, ''),
			pay_to_addr4 = ISNULL(b.addr4, ''),
			pay_to_addr5 = ISNULL(b.addr5, ''),
			pay_to_addr6 = ISNULL(b.addr6, '')
	FROM #apinpchg a, appayto b
	WHERE a.pay_to_code = b.pay_to_code
	AND a.vendor_code = b.vendor_code

	IF @@error != 0  
	BEGIN 
		RETURN 100
	END 

	
	UPDATE #apinpchg
		SET date_applied = @today
	WHERE date_applied <= 0

	IF @@error != 0  
	BEGIN 
		RETURN 100
	END 

	
	
	INSERT #get_missing_dates
	SELECT rec_id,
		terms_code,
		date_doc,
		ISNULL(date_due, 0),
		ISNULL(date_discount, 0)
	FROM #apinpchg
	WHERE	date_due = 0
	OR	date_discount = 0

	SELECT @loop_rec_id = MIN(rec_id)
	FROM #get_missing_dates

	
	WHILE @loop_rec_id IS NOT NULL
	BEGIN
		SELECT @terms_code = terms_code, 
			@date_doc  = date_doc
		FROM #get_missing_dates
		WHERE rec_id = @loop_rec_id
		
		
		IF ( @date_due = 0 )
			EXEC appdtdue_sp 4000, @terms_code, @date_doc, @date_due OUTPUT

		
		IF ( @date_discount = 0 )		
			EXEC appdtdsc_sp 4000, @terms_code, @date_doc,
			     @date_discount OUTPUT, @app_error_flag OUTPUT

		IF NOT ( @app_error_flag = 0 )	
		BEGIN		
			DROP TABLE #get_missing_dates
			RETURN 100
		END

		UPDATE #get_missing_dates
			SET date_due = ISNULL(@date_due,0),
				date_discount = ISNULL(@date_discount,0)
		WHERE rec_id = @loop_rec_id

		IF @@error != 0  
		BEGIN 
			DROP TABLE #get_missing_dates
			RETURN 100
		END
		
		
		SELECT @loop_rec_id = MIN(rec_id)
		FROM #get_missing_dates
		WHERE rec_id > @loop_rec_id

	END	

	
	UPDATE #apinpchg
		SET date_due = b.date_due,
			date_discount = b.date_discount
	FROM #apinpchg a, #get_missing_dates b
	WHERE a.rec_id = b.rec_id

	
	DROP TABLE #get_missing_dates

	
	UPDATE #apinpchg
		SET date_aging = date_due
	WHERE date_aging = 0

	SELECT @min_rec_id = MIN(rec_id)
	FROM #apinpchg

	SELECT @max_rec_id = MAX(rec_id) 
	FROM #apinpchg
	
	
	UPDATE apnumber
		SET    next_voucher_num = next_voucher_num + @max_rec_id

	
	SELECT @last_ctrl_num = next_voucher_num - @max_rec_id - 1, 
	       @ctrl_num_mask = voucher_num_mask
	FROM   apnumber

	
	IF (CHARINDEX('#', @ctrl_num_mask) > CHARINDEX('0', @ctrl_num_mask))
	BEGIN
		IF (CHARINDEX( '0', @ctrl_num_mask) > 0)
	    		SELECT @int_holder = CHARINDEX('0', @ctrl_num_mask)
   		ELSE
			SELECT @int_holder = CHARINDEX('#', @ctrl_num_mask)  
	END
	ELSE 
	BEGIN
		IF (CHARINDEX( '#', @ctrl_num_mask) > 0)
			SELECT @int_holder = CHARINDEX('#', @ctrl_num_mask) 
		ELSE
			SELECT @int_holder = CHARINDEX('0', @ctrl_num_mask) 
	END

	SELECT @num_len = vo_length
	FROM    apnumber

	UPDATE #apinpchg
		SET trx_ctrl_num = SUBSTRING(@ctrl_num_mask, 1, @int_holder - 1) +
		RIGHT('0000000000000000' + RTRIM(LTRIM(STR((@last_ctrl_num + rec_id), 16, 0))), @num_len)

	
  DROP TABLE #match_totals DROP TABLE #rounded_extended DROP TABLE #match_extended

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appoxhdr_sp] TO [public]
GO
