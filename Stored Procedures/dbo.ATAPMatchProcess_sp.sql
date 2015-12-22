SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                












































CREATE PROC	[dbo].[ATAPMatchProcess_sp]
AS

























  



					  

























































 

































































































































































































































































































CREATE TABLE #apterm
(
	date_doc		int,
	terms_code		varchar(8),
	date_due		int,
	date_discount   int
)







CREATE TABLE #ctrlpo 	( po_no	varchar(16), qty_invoiced float, part_no varchar(20), qty_received float,
			  PRIMARY KEY ( po_no , part_no ) 
			)
		
DECLARE @ctrl int, @invoice_qty2 int, @ctrl_rcp	int 

SET @ctrl  = 0 		
SET @invoice_qty2 = 0 	
SET @ctrl_rcp = 0 	


CREATE TABLE #atmtchdr ( invoice_no	varchar(20),	vendor_code	varchar(12),	amt_net		float,
			date_doc	int,		date_discount	int,		nat_cur_code	varchar(8),
			status		varchar(2),	source_module	varchar(4),	error_desc	varchar(255),		
			invalid_record	int,		amt_tax		float,		amt_discount	float,			
			amt_freight	float,		amt_misc	float,		matched		smallint,
			date_imported	int, 		org_id		varchar(30)	
			, at_tax_calc_flag int, tmp_tax_code varchar(8)) 

CREATE TABLE #atmtcdet ( invoice_no	varchar(20),	vendor_code	varchar(12),	po_no		varchar(16),
			part_no		varchar(30),	qty		float,		unit_price	float,				
			invalid_record	int,		sequence_id	int,		amt_tax		float,			
			amt_discount	float,		amt_freight	float,		amt_misc	float,
			matched		smallint,	source_module	varchar(4)
			)



DECLARE	@invoice_no	 	varchar(16),	@invoice_no_ant	varchar(16),	@vendor_code	varchar(12),
	@vendor_code_ant	varchar(12),	@part_no_ant	varchar(30),	@part_no	varchar(30),
	@po_no			varchar(16), 	@nat_cur_code	varchar(8),	@source_module	varchar(3),
	@source_module_ant	varchar(3),	@adm_group_by	varchar(20),	@prc_group_by	varchar(20),		
	@tolerance_code		varchar(8),	@message	varchar(40),	@status 	varchar(1),
	@next_trx		varchar(16),	@terms_code	varchar(8),	@tax_code	varchar(8),
	@location_code		varchar(10),	@rate_type_home	varchar(8),	@rate_type_oper	varchar(8),
	@user_trx_type_code	varchar(8),	@posting_code	varchar(8),	@branch_code	varchar(8),	
	@vend_class_code	varchar(8),	@comment_code	varchar(8),	@fob_code	varchar(8),
	@payment_code		varchar(8),	@attention_name	varchar(40),	@attention_phone varchar(30),
	@code_1099		varchar(8),	@batch_code	varchar(16),	@company_code	varchar(16),
	@org_id			varchar(30),	@trx_ctrl_num		varchar(16), 	
	@match_ctrl_num	varchar(16) 

DECLARE	@adm_installed 		smallint,	@vo_hold_flag	smallint,	@po_item_flag		smallint,		
	@tolerance_type		smallint, 	@active_flag	smallint, 	@tolerance_basis 	smallint,  		
	@over_flag 		smallint, 	@under_flag 	smallint, 	@display_msg_flag	smallint,		
	@start_user_id		smallint,	@precision	smallint,	@sequence_id		int,		
	@put_on_hold		int,		@result		int,		@po_line		int,		
	@num			int,		@adm_next_match_no int,		@today			int,		
	@batch_mode		int,		@actual_number	int,		@sequence_id_match	int, 
	@match_ctrl_int		int , @apply	int , @match_receiptdate_flag smallint ,
	@match_requestdate_flag smallint 
	,@voprocs_invoice_taxflag int

DECLARE @invoice_qty		float,		@receipt_qty	float,		@invoice_price		float,
	@receipt_price		float,		@basis_value 	float,		@actual_total		float,
	@amt_misc_sum		float,				@amt_tax_sum		float,
	@amt_freight_sum	float,				@amt_disc_sum		float,
        @company_id 		int,		@str_msg_at	VARCHAR(255)


declare @mt_ctrl_num varchar(16)

declare @process_ctrl_num varchar(16)

declare @smuser_id int

SELECT      @company_code = company_code

      from glco 

set @smuser_id = user_id()

EXEC appgetstring_sp 'STR_AUT_MATCH_POST', @str_msg_at  OUT
 

      EXEC @result = pctrladd_sp @process_ctrl_num OUTPUT,  

      @str_msg_at, @smuser_id, 4000, @company_code, 4065 






select @company_id = company_id  from glco (nolock)

SELECT @adm_installed =  ISNULL((SELECT 1 FROM sminstap_vw WHERE app_id = 18000 AND company_id = @company_id ),0)








UPDATE atmtchdr
SET org_id = ( SELECT default_matching_organization FROM epmchopt d, glco g WHERE g.company_id = d.company_id)
WHERE LEN(RTRIM(LTRIM(ISNULL(org_id,'')))) = 0






INSERT #atmtchdr (	invoice_no,		vendor_code,		amt_net,	date_doc,	date_discount,		
			nat_cur_code,		status,			source_module,	invalid_record,	amt_tax,
			amt_discount,		amt_freight,		amt_misc,	matched,	date_imported,
			org_id	)
SELECT			invoice_no,		vendor_code,		amt_net,	date_doc,	date_discount,		
			nat_cur_code,		status,			source_module,	0,		amt_tax,
			amt_discount,		amt_freight,		amt_misc,	0,		date_imported,
			org_id
FROM	atmtchdr
WHERE	status IN	('N','A','R')
ORDER BY invoice_no, vendor_code

INSERT #atmtcdet (	invoice_no,		vendor_code,		po_no,		part_no,	qty,	
			unit_price,		source_module,		invalid_record,	sequence_id,	matched,
			amt_tax,		amt_discount,		amt_freight,		amt_misc	)
SELECT 			det.invoice_no,		det.vendor_code,	det.po_no,	det.part_no,	det.qty,	
			det.unit_price,		'',			1,		sequence_id,	0,
			det.amt_tax,		det.amt_discount,	det.amt_freight,det.amt_misc	
FROM	#atmtchdr hdr, atmtcdet det
WHERE	hdr.invoice_no 	= det.invoice_no 
AND	hdr.vendor_code = det.vendor_code
ORDER BY hdr.invoice_no, hdr.vendor_code




DELETE atmtcerr	




INSERT atmtcerr (invoice_no,	vendor_code,	po_no,	sequence_id,	part_no,	qty,	unit_price,	error_flag )
SELECT 		invoice_no,	vendor_code,	po_no,	sequence_id,	part_no, 	0,	0,		0
FROM	#atmtcdet




UPDATE	at_det
SET 	at_det.invalid_record = 0, at_det.source_module = 'PRC'
FROM	#atmtcdet at_det, epinvhdr hdr,  epinvdtl dtl
WHERE 	hdr.receipt_ctrl_num = dtl.receipt_ctrl_num 	
	AND at_det.vendor_code 	= hdr.vendor_code
	AND at_det.po_no 	= hdr.po_ctrl_num
	AND at_det.part_no 	= dtl.item_code





UPDATE	at_det
SET 	at_det.invalid_record = 2, at_det.source_module = 'PRC'
FROM	#atmtcdet at_det, epinvhdr hdr,  epinvdtl dtl
WHERE 	hdr.receipt_ctrl_num = dtl.receipt_ctrl_num 	
	AND at_det.vendor_code 	= hdr.vendor_code
	AND at_det.po_no 	= hdr.po_ctrl_num
	AND at_det.part_no 	= dtl.item_code
	AND dtl.invoiced_full_flag = 1




IF (@adm_installed = 1 )
BEGIN
	UPDATE	det
	SET 	det.invalid_record = 0, det.source_module = 'ADM'
	FROM	#atmtcdet det, receipts rec 
	WHERE 	det.vendor_code 	= rec.vendor
		AND det.po_no 		= rec.po_no
		AND det.part_no 	= rec.part_no
END




EXEC appgetstring_sp 'STR_NO_RECEIPT_INFO', @str_msg_at  OUT

UPDATE 	hdr
SET	hdr.status = 'R', 
	
	hdr.error_desc = @str_msg_at, 
	hdr.num_failed = hdr.num_failed + 1
FROM	atmtchdr hdr, #atmtcdet det
WHERE	hdr.invoice_no = det.invoice_no
AND	hdr.vendor_code = det.vendor_code 
AND	det.invalid_record = 1





EXEC appgetstring_sp 'STR_INVOICED_IN_FULL', @str_msg_at  OUT

UPDATE 	hdr
SET	hdr.status = 'R', 
	
	hdr.error_desc = @str_msg_at, 
	hdr.num_failed = hdr.num_failed + 1
FROM	atmtchdr hdr, #atmtcdet det
WHERE	hdr.invoice_no = det.invoice_no
AND	hdr.vendor_code = det.vendor_code 
AND	det.invalid_record = 2




CREATE TABLE #det_orgs
(
	po_no			varchar(16),
	part_no			varchar(30),
	org_id			varchar(30),
	acct_code		varchar(32)
)

IF (@adm_installed = 1 )
BEGIN
		INSERT INTO  #det_orgs ( part_no , 	po_no, 	org_id, 	acct_code )
		SELECT DISTINCT b.part_no,b.po_no,dbo.IBOrgbyAcct_fn(e.account_no) org_id,e.account_no acct_code
		FROM  #atmtcdet b,  receipts e, pur_list f 
		WHERE 
		 b.part_no 		= e.part_no
		AND b.po_no 		= e.po_no
		AND b.part_no 		= f.part_no  
		AND b.po_no 		= f.po_no  
		UNION 
		SELECT  DISTINCT  b.part_no, b.po_no, dbo.IBOrgbyAcct_fn(e.account_code) org_id, e.account_code acct_code
		FROM   #atmtcdet b, epinvdtl e , epinvhdr h
		WHERE  
		 b.part_no 		= e.item_code
		AND h.receipt_ctrl_num 	= e.receipt_ctrl_num
		AND upper(h.po_ctrl_num) = upper(b.po_no)
END
ELSE
BEGIN
		INSERT INTO  #det_orgs ( part_no , 	po_no, 	org_id, 	acct_code )
		SELECT  DISTINCT  b.part_no, b.po_no, dbo.IBOrgbyAcct_fn(e.account_code) org_id, e.account_code acct_code
		FROM   #atmtcdet b, epinvdtl e , epinvhdr h
		WHERE  
		 b.part_no 		= e.item_code
		AND h.receipt_ctrl_num 	= e.receipt_ctrl_num
		AND upper(h.po_ctrl_num) = upper(b.po_no)


END




IF (SELECT err_type FROM epedterr WHERE err_code = 00200) <= 0
BEGIN

	EXEC appgetstring_sp 'STR_ORG_IN_HEADER_INVALID', @str_msg_at  OUT

	UPDATE 	#atmtchdr
		SET invalid_record = 00200
	WHERE org_id NOT IN ( SELECT org_id FROM dbo.IB_Organization_vw )

	UPDATE 	atmtchdr
	SET	status = 'R', 
		num_failed = hdr.num_failed + 1,
		error_desc = @str_msg_at
	FROM	atmtchdr hdr, #atmtchdr h
	WHERE	hdr.invoice_no 	= h.invoice_no
	AND	hdr.vendor_code = h.vendor_code
	AND 	h.invalid_record = 00200

END




IF (SELECT err_type FROM epedterr WHERE err_code = 00230) <= 0
BEGIN
	EXEC appgetstring_sp 'STR_ORG_IN_DETAIL_INVALID', @str_msg_at  OUT

	UPDATE  #atmtcdet
		SET  invalid_record = 00230
	FROM  #atmtcdet det, #det_orgs orgs
	WHERE
	 	det.po_no = orgs.po_no 
	AND     det.part_no = orgs.part_no
	AND 	orgs.org_id    NOT IN ( SELECT org_id FROM dbo.IB_Organization_vw )

	UPDATE 	atmtchdr
		SET	status = 'R', 
			num_failed = hdr.num_failed + 1,
			error_desc = @str_msg_at
		FROM	atmtchdr hdr, #atmtcdet det
		WHERE	hdr.invoice_no 	= det.invoice_no
		AND	hdr.vendor_code = det.vendor_code
		AND	det.invalid_record = 00230
END





IF (SELECT err_type FROM epedterr WHERE err_code = 00210) <= 0
BEGIN

	EXEC appgetstring_sp 'STR_NO_INTERORG_RELATION', @str_msg_at  OUT

	UPDATE  #atmtcdet
		SET  invalid_record = 00210
	FROM  #atmtchdr a, #atmtcdet det, #det_orgs orgs,  iborgsameandrels_vw r
	WHERE 	a.invoice_no 	= det.invoice_no 
	AND	a.vendor_code = det.vendor_code
	AND 	det.po_no = orgs.po_no 
	AND     det.part_no = orgs.part_no
  	AND 	r.controlling_org_id = a.org_id
	AND 	orgs.org_id NOT IN ( SELECT detail_org_id FROM iborgsameandrels_vw WHERE controlling_org_id = a.org_id )

	UPDATE 	atmtchdr
		SET	status = 'R', 
			num_failed = hdr.num_failed + 1,
			error_desc = @str_msg_at
		FROM	atmtchdr hdr, #atmtcdet det
		WHERE	hdr.invoice_no 	= det.invoice_no
		AND	hdr.vendor_code = det.vendor_code
		AND	det.invalid_record = 00210
END




IF (SELECT err_type FROM epedterr WHERE err_code = 00220) <= 0
BEGIN
	EXEC appgetstring_sp 'STR_NO_INTERORG_ACCOUNT_MAP', @str_msg_at  OUT

	UPDATE  #atmtcdet
		SET  invalid_record = 00220
	FROM  #atmtchdr a, #atmtcdet det , #det_orgs orgs
	WHERE 	a.invoice_no 	= det.invoice_no 
	AND	a.vendor_code = det.vendor_code
	AND 	det.po_no = orgs.po_no 
	AND     det.part_no = orgs.part_no
	AND 	a.org_id <> orgs.org_id
	AND 	det.invalid_record = 0

	UPDATE  #atmtcdet
		SET  invalid_record = 0
	FROM  #atmtchdr a, #atmtcdet det, #det_orgs orgs,  OrganizationOrganizationDef r
	WHERE 	a.invoice_no 	= det.invoice_no 
	AND	a.vendor_code = det.vendor_code
	AND 	det.po_no = orgs.po_no 
	AND     det.part_no = orgs.part_no
  	AND 	r.controlling_org_id = a.org_id
	AND 	r.detail_org_id = orgs.org_id
	AND	orgs.acct_code like r.account_mask 
	AND     det.invalid_record = 00220
	
	UPDATE 	atmtchdr
		SET	status = 'R', 
			num_failed = hdr.num_failed + 1,
			error_desc = @str_msg_at
		FROM	atmtchdr hdr, #atmtcdet det
		WHERE	hdr.invoice_no 	= det.invoice_no
		AND	hdr.vendor_code = det.vendor_code
		AND	det.invalid_record = 00220
END



DROP TABLE #det_orgs



DELETE 	hdr
FROM	#atmtchdr hdr, #atmtcdet det
WHERE	hdr.invoice_no = det.invoice_no
AND	hdr.vendor_code = det.vendor_code 
AND	det.invalid_record in (1,2, 00200, 00220,00210, 00230)











UPDATE err
SET error_flag  = 1
FROM #atmtcdet det, atmtcerr err
WHERE	det.invoice_no = err.invoice_no
AND	det.vendor_code = err.vendor_code
AND	det.part_no 	= err.part_no
AND	det.invalid_record in (1,2, 00200, 00220,00210, 00230)

DELETE 	det
FROM	#atmtcdet det
WHERE 	det.invoice_no IN (SELECT DISTINCT invoice_no FROM #atmtcdet  WHERE invalid_record in (1,2, 00200, 00220,00210, 00230) )




IF ((SELECT COUNT(invoice_no) FROM #atmtchdr)  = 0)
BEGIN
	RETURN 0
END




UPDATE 	hdr
SET	hdr.source_module = det.source_module, 
	hdr.error_desc = ''
FROM	atmtchdr hdr, #atmtcdet det
WHERE	hdr.invoice_no = det.invoice_no
AND	hdr.vendor_code = det.vendor_code 
AND	hdr.status in ('A','R','N')   


UPDATE 	hdr
SET	hdr.source_module = det.source_module, 
	hdr.error_desc = ''
FROM	#atmtchdr hdr, #atmtcdet det
WHERE	hdr.invoice_no = det.invoice_no
AND	hdr.vendor_code = det.vendor_code 
AND	hdr.status in ('N')





SELECT @today = datediff( day, '01/01/1900', getdate() ) + 693596






select @voprocs_invoice_taxflag = voprocs_invoice_taxflag from atco 



CREATE TABLE #tbl_vendorconfig 
	(vendor_code varchar(12)  PRIMARY KEY, 
	voprocs_invoice_taxflag int, at_usevendor_prorate_setting int, voprocs_amount_acc_expense int, 
	tax_flag int, tax_per_1line_2qty_3amt int,
	freight_flag int, freight_per_1line_2qty_3amt int,
	disc_flag int, disc_per_1line_2qty_3amt int, 
	misc_flag int, misc_per_1line_2qty_3amt int,
	at_tax_calc_flag int, tmp_tax_code varchar(8))

INSERT INTO #tbl_vendorconfig (vendor_code, voprocs_invoice_taxflag, at_usevendor_prorate_setting, voprocs_amount_acc_expense,
      tax_flag, tax_per_1line_2qty_3amt,
      freight_flag, freight_per_1line_2qty_3amt, 
      disc_flag, disc_per_1line_2qty_3amt, 
      misc_flag, misc_per_1line_2qty_3amt,
      at_tax_calc_flag, 
	  tmp_tax_code)
SELECT DISTINCT a.vendor_code, @voprocs_invoice_taxflag, isnull(at_usevendor_prorate_setting,0), isnull(t.voprocs_amount_acc_expense, 0),
      isnull(t.tax_flag, 0), isnull(t.tax_per_1line_2qty_3amt,3),
      isnull(t.freight_flag, 0), isnull(t.freight_per_1line_2qty_3amt,3), 
      isnull(t.disc_flag, 0), isnull(t.disc_per_1line_2qty_3amt,3), 
      isnull(t.misc_flag, 0), isnull(t.misc_per_1line_2qty_3amt,3),
	  CASE WHEN ((t.at_tax_code_flag = 1 AND LEN(LTRIM(RTRIM(isnull(t.at_tax_code,''))))>0) AND @voprocs_invoice_taxflag = 1) THEN 1 ELSE 0 END,
	  CASE WHEN ((t.at_tax_code_flag = 1 AND LEN(LTRIM(RTRIM(isnull(t.at_tax_code,''))))>0) AND @voprocs_invoice_taxflag = 1) THEN t.at_tax_code ELSE t.tax_code END
FROM #atmtchdr a, atapvend t (nolock)
WHERE a.vendor_code = t.vendor_code


UPDATE x
SET 	x.voprocs_invoice_taxflag = t.voprocs_invoice_taxflag, 
	x.voprocs_amount_acc_expense = t.voprocs_amount_acc_expense, 
	x.tax_flag = t.tax_flag, 
	x.tax_per_1line_2qty_3amt = t.tax_per_1line_2qty_3amt,
	x.freight_flag = t.freight_flag, 
	x.freight_per_1line_2qty_3amt = t.freight_per_1line_2qty_3amt, 
	x.disc_flag = t.disc_flag, 
	x.disc_per_1line_2qty_3amt = t.disc_per_1line_2qty_3amt, 
	x.misc_flag = t.misc_flag, 
	x.misc_per_1line_2qty_3amt = t.misc_per_1line_2qty_3amt
FROM #tbl_vendorconfig x, atco t (nolock)
WHERE x.at_usevendor_prorate_setting = 0




UPDATE a
SET a.tmp_tax_code = c.tmp_tax_code,
	a.at_tax_calc_flag = c.at_tax_calc_flag
FROM	#atmtchdr a INNER JOIN #tbl_vendorconfig c 
	ON (a.vendor_code = c.vendor_code)




EXEC atval_sp




EXEC ATTaxProRate_sp






CREATE TABLE #epmchhdr ( match_ctrl_num		varchar(16),	vendor_code		varchar(12),	vendor_remit_to		varchar(8),
			vendor_invoice_no	varchar(20),	date_match		int,		tolerance_hold_flag	smallint,
			tolerance_approval_flag	smallint,	validated_flag		smallint,	vendor_invoice_date	int,
			invoice_receive_date	int,		apply_date		int,		aging_date		int,
			due_date		int,		discount_date		int,		amt_net			float,
			amt_discount		float,		amt_tax			float,		amt_freight		float,
			amt_misc		float,		amt_due			float,		match_posted_flag	smallint,
			amt_tax_included	float,		trx_ctrl_num		varchar(16),	nat_cur_code		varchar(8),
			rate_type_home		varchar(8),	rate_type_oper		varchar(8),	rate_home		float,
			rate_oper		float,		batch_code		varchar(16),
			org_id			varchar(30))
CREATE TABLE #epmchdtl ( match_dtl_key		varchar(50),	match_ctrl_num		varchar(16),	sequence_id 		int,
			po_ctrl_num		varchar(16),	po_sequence_id		int,		receipt_ctrl_num 	varchar(16),
			receipt_dtl_key		varchar(50),	account_code		varchar(32),	reference_code		varchar(32),
			company_id		int,		qty_received		float,		qty_invoiced		float,
			qty_prev_invoiced	float,		amt_prev_invoiced	float,		unit_price		float,
			invoice_unit_price	float,		tolerance_hold_flag	smallint,	match_posted_flag 	smallint,
			tax_code		varchar(8),	amt_tax			float,		amt_tax_included	float,
			calc_tax		float,		invoice_no		varchar(20),	vendor_code		varchar(12) 	  			)

CREATE TABLE #mtinptax (match_ctrl_num		varchar(16),	trx_type		smallint,	sequence_id		int,	
			tax_type_code		varchar(8),	amt_taxable		float,		amt_gross		float,		
			amt_tax			float,		amt_final_tax		float )

CREATE TABLE #adm_pomchchg( match_ctrl_int	int,		vendor_code		varchar(12),	vendor_remit_to		varchar(8),
			vendor_invoice_no	varchar(20),	date_match		datetime,	printed_flag		smallint,
			vendor_invoice_date	int,		invoice_receive_date	int,		apply_date		int,
			aging_date		int,		due_date		int,		discount_date		int,
			amt_net			decimal(20,8),	amt_discount		decimal(20,8),	amt_tax			decimal(20,8),
			amt_freight		decimal(20,8),	amt_misc		decimal(20,8),	amt_due			decimal(20,8),
			match_posted_flag	smallint,	nat_cur_code		varchar(8),	amt_tax_included	decimal(20,8),
			trx_type		int,		po_no			int,		location		varchar(10),
			amt_gross		decimal(20,8),	process_group_num	varchar(16),	rate_type_home		varchar(8),
			rate_type_oper		varchar(8),	curr_factor		decimal(20,8),	oper_factor		decimal(20,8),
			tax_code		varchar(8),	terms_code		varchar(8),	org_id			varchar(30))
CREATE TABLE #adm_pomchcdt ( match_ctrl_int	int,		match_line_num 		int,		po_ctrl_num 		varchar(16),
			po_ctrl_int 		int,		po_line_num 		int,		gl_acct 		varchar(32),	
			qty_ordered 		decimal(20,8),	unit_price 		decimal(20,8),	match_unit_price 	decimal(20,8),
			qty_invoiced 		decimal(20,8),	match_posted_flag 	int,		conv_factor 		decimal(20,8),
			part_no 		varchar(30),	item_desc 		varchar(60),	gl_ref_code 		varchar(32),
			tax_code 		varchar(8),	amt_tax 		decimal(20,8),	amt_tax_included 	decimal(20,8),
			calc_tax 		decimal(20,8),	receipt_no 		int,		location 		varchar(10),
			nat_curr 		varchar(8),	oper_factor 		decimal(20,8),	curr_factor 		decimal(18,0),
			oper_cost 		decimal(20,8),	curr_cost 		decimal(20,8),	misc 			char(1),
			invoice_no		varchar(20),	vendor_code		varchar(12) 				)

CREATE TABLE #apinpchg (trx_ctrl_num		varchar(16),	trx_type		smallint,	doc_ctrl_num		varchar(16),
			apply_to_num		varchar(16),	user_trx_type_code	varchar(8),	batch_code		varchar(16),
			po_ctrl_num		varchar(16),	vend_order_num		varchar(20),	ticket_num		varchar(20),
			date_applied		int,		date_aging		int,		date_due		int,
			date_doc		int,		date_entered		int,		date_received		int,
			date_required		int,		date_recurring		int,		date_discount		int,
			posting_code		varchar(8),	vendor_code		varchar(12),	pay_to_code		varchar(8),
			branch_code		varchar(8),	class_code		varchar(8),	approval_code		varchar(8),
			comment_code		varchar(8),	fob_code		varchar(8),	terms_code		varchar(8),
			tax_code		varchar(8),	recurring_code		varchar(8),	location_code		varchar(8),
			payment_code		varchar(8),	times_accrued		smallint,	accrual_flag		smallint,
			drop_ship_flag		smallint,	posted_flag		smallint,	hold_flag		smallint not null,
			add_cost_flag		smallint,	approval_flag		smallint,	recurring_flag		smallint,
			one_time_vend_flag	smallint,	one_check_flag		smallint,	amt_gross		float,
			amt_discount		float,		amt_tax			float,		amt_freight		float,
			amt_misc		float,		amt_net			float,		amt_paid		float,
			amt_due			float,		amt_restock		float,		amt_tax_included	float,
			frt_calc_tax		float,		doc_desc		varchar(40),	hold_desc		varchar(40),
			user_id			smallint,	next_serial_id		smallint,	attention_name		varchar(40),
			attention_phone		varchar(30),	intercompany_flag	smallint,	company_code		varchar(8),
			cms_flag		smallint,	process_group_num 	varchar(16),	nat_cur_code 		varchar(8),
			rate_type_home 		varchar(8),	rate_type_oper		varchar(8),	rate_home 		float,
			rate_oper		float,		net_original_amt	float,		org_id varchar(30) NULL,tax_freight_no_recoverable float 
			, at_tax_calc_flag int) 

CREATE TABLE #apinpage (trx_ctrl_num 		varchar(16),	trx_type		smallint,	sequence_id		int,
			date_applied 		int,		date_due		int,		date_aging		int,
			amt_due			float)

CREATE TABLE #apinpcdt (trx_ctrl_num		varchar(16),	trx_type 		smallint,	sequence_id 		int,
			location_code 		varchar(8),	item_code 		varchar(30),	bulk_flag 		smallint,
			qty_ordered 		float,		qty_received 		float,		qty_returned 		float,
			qty_prev_returned 	float,		approval_code		varchar(8),	tax_code 		varchar(8),
			return_code 		varchar(8),	code_1099 		varchar(8),	po_ctrl_num 		varchar(16),
			unit_code 		varchar(8),	unit_price 		float,		amt_discount 		float,
			amt_freight 		float,		amt_tax 		float,		amt_misc 		float,
			amt_extended 		float,		calc_tax 		float,		date_entered 		int,
			gl_exp_acct 		varchar(32),	new_gl_exp_acct 	varchar(32),	rma_num 		varchar(20),
			line_desc 		varchar(60),	serial_id 		int,		company_id 		smallint,
			iv_post_flag 		smallint,	po_orig_flag 		smallint,	rec_company_code 	varchar(8),
			new_rec_company_code	varchar(8),	reference_code		varchar(32),	new_reference_code	varchar(32),		
			org_id varchar(30) NULL,	amt_nonrecoverable_tax	float,	amt_tax_det	float	)

CREATE TABLE #apinptax (trx_ctrl_num		varchar(16),	trx_type		smallint,	sequence_id		int,
			tax_type_code		varchar(8),	amt_taxable		float,		amt_gross		float,
			amt_tax			float,		amt_final_tax		float,		trx_state		smallint NULL,	
			mark_flag		smallint NULL)


CREATE TABLE #temp_apinpcdt (trx_ctrl_num		varchar(16),	trx_type 		smallint,	sequence_id 		int,
			location_code 		varchar(8),	item_code 		varchar(30),	bulk_flag 		smallint,
			qty_ordered 		float,		qty_received 		float,		qty_returned 		float,
			qty_prev_returned 	float,		approval_code		varchar(8),	tax_code 		varchar(8),
			return_code 		varchar(8),	code_1099 		varchar(8),	po_ctrl_num 		varchar(16),
			unit_code 		varchar(8),	unit_price 		float,		amt_discount 		float,
			amt_freight 		float,		amt_tax 		float,		amt_misc 		float,
			amt_extended 		float,		calc_tax 		float,		date_entered 		int,
			gl_exp_acct 		varchar(32),	new_gl_exp_acct 	varchar(32),	rma_num 		varchar(20),
			line_desc 		varchar(60),	serial_id 		int,		company_id 		smallint,
			iv_post_flag 		smallint,	po_orig_flag 		smallint,	rec_company_code 	varchar(8),
			new_rec_company_code	varchar(8),	reference_code		varchar(32),	new_reference_code	varchar(32)	)

CREATE TABLE #apinptaxdtl(trx_ctrl_num		varchar(16),	sequence_id		integer,						
			  trx_type		integer,	tax_sequence_id		integer,	detail_sequence_id	integer,
			  tax_type_code		varchar(8),	amt_taxable		float,		amt_gross		float,
			  amt_tax		float,		amt_final_tax		float,		recoverable_flag	integer,	
			  account_code		varchar(32))											




SELECT 	@tolerance_type 	= tolerance_type,	@active_flag 	= active_flag,	@tolerance_basis 	= tolerance_basis,
	@basis_value 		= basis_value,		@over_flag 	= over_flag,	@under_flag 		= under_flag,
	@display_msg_flag	= display_msg_flag,	@message 	= message,	@tolerance_code = hdr.tolerance_code
FROM 	epmchopt hdr, eptollin det
WHERE 	hdr.tolerance_code = det.tolerance_code 




select @tax_code = tax_code from apco






---Add the GROUP BY clause
---Modify the det.sequence_id to dtl.sequence_id in the SELECT clause
INSERT #epmchdtl( match_dtl_key,	match_ctrl_num,		sequence_id,		po_ctrl_num,		po_sequence_id,			
		receipt_ctrl_num,	receipt_dtl_key,	account_code,		reference_code,		company_id,		
		qty_received,		qty_invoiced,		qty_prev_invoiced,	amt_prev_invoiced,	unit_price,
		invoice_unit_price,	tolerance_hold_flag,	match_posted_flag,	tax_code,		amt_tax,			
		amt_tax_included,	calc_tax,		invoice_no,		vendor_code	)
SELECT 		match_dtl_key = '',	match_ctrl_num = '',			dtl.sequence_id,	det.po_no,		po_sequence_id,			
		hdr.receipt_ctrl_num,	receipt_detail_key,	account_code,		reference_code,		hdr.company_id,
		dtl.qty_received ,	det.qty,		0,			0,			det.unit_price,
		0, 0, 0, isnull(CASE WHEN cfg.at_tax_calc_flag = 1 THEN cfg.tmp_tax_code ELSE dtl.tax_code END,@tax_code), det.amt_tax,
		0,			det.amt_tax,		det.invoice_no,		det.vendor_code
FROM	#atmtcdet det, epinvhdr hdr,  epinvdtl dtl, #tbl_vendorconfig cfg
WHERE 	hdr.receipt_ctrl_num 	= dtl.receipt_ctrl_num
	AND det.vendor_code 	= hdr.vendor_code
	AND det.po_no 		= hdr.po_ctrl_num
	AND det.part_no 	= dtl.item_code
	AND cfg.vendor_code	= det.vendor_code
	



	AND dtl.invoiced_full_flag != 1
GROUP BY dtl.sequence_id,	det.po_no,	po_sequence_id,	hdr.receipt_ctrl_num,	receipt_detail_key,	account_code, reference_code,		
		hdr.company_id,dtl.qty_received ,	det.qty,det.unit_price,det.amt_tax,dtl.tax_code,	det.amt_tax,		det.invoice_no,		
		det.vendor_code
		, cfg.at_tax_calc_flag, cfg.tmp_tax_code


IF (@adm_installed = 1 )
BEGIN
	
	INSERT 	#adm_pomchcdt(match_ctrl_int,	match_line_num,		po_ctrl_num,		po_ctrl_int,		po_line_num,
		gl_acct,		qty_ordered,		unit_price,		match_unit_price,	qty_invoiced,
		match_posted_flag,	conv_factor,		part_no,		item_desc,		gl_ref_code,
		tax_code,		amt_tax,		amt_tax_included,	calc_tax,		receipt_no,
		location,		nat_curr,		oper_factor,		curr_factor,		oper_cost,		
		curr_cost,		misc,			invoice_no,		vendor_code )
--Rev1.0	SELECT 			0,		0,			rec.po_no,		rec.po_key,			1,
	SELECT 			0,		sequence_id,			rec.po_no,		rec.po_key,			1,
		rec.account_no,		det.qty,		rec.unit_cost,		rec.unit_cost,		det.qty,
		0,			rec.conv_factor,	det.part_no,		'',			'',
		pur.tax_code,		0,			0,			det.amt_tax,		rec.receipt_no,
		rec.location,		nat_curr,		rec.oper_factor,	rec.curr_factor,	rec.oper_cost,		
		rec.curr_cost,		'N',			invoice_no,		det.vendor_code
	FROM	#atmtcdet det, receipts rec, pur_list pur
	WHERE 	det.vendor_code 	= rec.vendor
		AND det.po_no 		= rec.po_no
		AND det.part_no 	= rec.part_no
		AND det.po_no		= pur.po_no
		AND pur.part_no		= det.part_no

END






DECLARE	invoice_tolerance SCROLL CURSOR FOR
		SELECT 	det.invoice_no, det.vendor_code, det.source_module, det.po_no, det.part_no, det.qty, det.unit_price, cur.curr_precision
		FROM 	#atmtcdet det, #atmtchdr hdr, glcurr_vw cur
		WHERE	det.matched = 0
		AND	hdr.nat_cur_code = cur.currency_code
		AND	hdr.invoice_no = det.invoice_no
		AND	hdr.vendor_code = det.vendor_code
		AND	hdr.status != 'A'
		ORDER BY det.invoice_no, det.vendor_code

OPEN	invoice_tolerance 

FETCH	invoice_tolerance
INTO	@invoice_no, @vendor_code, @source_module, @po_no, @part_no, @invoice_qty, @invoice_price, @precision




SELECT 	@ctrl_rcp = COUNT(hdr.receipt_ctrl_num)
FROM	epinvhdr hdr
WHERE  	upper(hdr.po_ctrl_num) = upper(@po_no)


WHILE @@FETCH_STATUS = 0
BEGIN





	IF NOT EXISTS (SELECT po_no,part_no FROM #ctrlpo WHERE po_no = @po_no AND part_no = @part_no)
		BEGIN
			INSERT #ctrlpo (po_no, qty_invoiced,  part_no, qty_received  )
				VALUES (@po_no,           0 , @part_no,            0 )	
		END

	
	SELECT 	@po_item_flag	= ISNULL(po_item_flag,0)
	FROM	apvend
	WHERE	vendor_code = @vendor_code

	


	IF (@source_module = 'PRC')
	BEGIN
		
		IF (@po_item_flag = 1)
		BEGIN
			SELECT	@receipt_price = MAX(unit_price), @receipt_qty =  SUM(dtl.qty_received)
			FROM	epinvhdr hdr,  epinvdtl dtl 
			WHERE 	hdr.receipt_ctrl_num 	= dtl.receipt_ctrl_num 
				AND hdr.vendor_code	= @vendor_code
				AND hdr.po_ctrl_num	= @po_no
				AND dtl.item_code 	= @part_no
			GROUP BY hdr.po_ctrl_num, dtl.item_code
		END
		ELSE
		BEGIN
			SELECT	@receipt_price = MAX(unit_price), @receipt_qty = SUM(dtl.qty_received)
			FROM	epinvhdr hdr,  epinvdtl dtl 
			WHERE 	hdr.receipt_ctrl_num 	= dtl.receipt_ctrl_num 
				AND hdr.vendor_code	= @vendor_code
				AND hdr.po_ctrl_num	= @po_no
				AND dtl.item_code 	= @part_no
			GROUP BY hdr.po_ctrl_num, hdr.date_accepted, dtl.item_code
		END

		



		SELECT  @ctrl 	= qty_invoiced
		FROM 	#ctrlpo
		WHERE	po_no	=  @po_no
		AND 	part_no	=  @part_no
			
		SET @invoice_qty2 = @invoice_qty + @ctrl			

		


		EXEC @result = ATPRCCheckTolerance_sp	@tolerance_code	,
							@receipt_qty 	,		
							@invoice_qty2 	,
							0		,	-- @qty_prev_invoiced 	,
							0		,	--@amt_prev_invoiced 	,
							@receipt_price 	,
							@invoice_price 	,
							@precision	,
							@put_on_hold	OUTPUT
	END	
	ELSE
	BEGIN
		IF (@adm_installed = 1 AND @source_module = 'ADM')
		BEGIN
			IF (@po_item_flag = 1)
			BEGIN
				SELECT 	@receipt_price = MAX(unit_cost),@receipt_qty = SUM(quantity), @po_line = MAX(po_line)
				FROM	receipts
				WHERE	po_no	= @po_no	
				AND	part_no	= @part_no
				GROUP BY po_no, part_no
			END
			ELSE
			BEGIN
				SELECT 	@receipt_price = MAX(unit_cost),@receipt_qty = SUM(quantity), @po_line = MAX(po_line)
				FROM	receipts
				WHERE	po_no	= @po_no	
				AND	part_no	= @part_no
				GROUP BY po_no, part_no, release_date
			END
		END 

		


		EXEC @result = ATADMCheckTolerance_sp 	@part_no 	,
							@invoice_qty 	,
							@receipt_qty	,
							@po_no		,
							@po_line	,
							@invoice_price	,
							@receipt_price	,
							@precision	,
							@put_on_hold 	OUTPUT	
	END

	IF @put_on_hold != 0
	BEGIN
		UPDATE 	atmtcerr
		SET	error_flag = 1, qty = @receipt_qty,	unit_price = @receipt_price
		WHERE	invoice_no 	= @invoice_no
		AND	vendor_code 	= @vendor_code
		AND	po_no		= @po_no
		AND	part_no		= @part_no

		UPDATE 	#atmtcdet
		SET 	invalid_record 	= 1
		WHERE	invoice_no 	= @invoice_no
		AND	vendor_code 	= @vendor_code
		AND	po_no		= @po_no
		AND	part_no		= @part_no

	END
	ELSE
	BEGIN
		UPDATE 	atmtcerr
		SET	qty = @receipt_qty,	unit_price = @receipt_price
		WHERE	invoice_no 	= @invoice_no
		AND	vendor_code 	= @vendor_code
		AND	po_no		= @po_no
		AND	part_no		= @part_no
	
		



		UPDATE #ctrlpo
		SET 	qty_invoiced 	= @ctrl + @invoice_qty, qty_received =+ @receipt_qty
		WHERE	po_no		= @po_no
		AND 	part_no		= @part_no
	END



	FETCH invoice_tolerance
	INTO	@invoice_no, @vendor_code, @source_module, @po_no, @part_no, @invoice_qty, @invoice_price, @precision

END

CLOSE invoice_tolerance
DEALLOCATE invoice_tolerance





IF EXISTS (SELECT 1 FROM #atmtcdet 
		WHERE	invalid_record = 1	)
BEGIN

	EXEC appgetstring_sp 'STR_TOLERANCE_VALIDATION', @str_msg_at  OUT

	UPDATE 	hdr
	SET	hdr.status = 'R', 
		hdr.num_failed = hdr.num_failed + 1,
		error_desc = @str_msg_at
	FROM	atmtchdr hdr, #atmtcdet det
	WHERE	hdr.invoice_no 	= det.invoice_no
	AND	hdr.vendor_code = det.vendor_code
	AND	det.invalid_record = 1

	DELETE 	adm
	FROM	#adm_pomchcdt adm, #atmtcdet det
	WHERE	adm.invoice_no 	= det.invoice_no
	AND	adm.vendor_code = det.vendor_code
	AND	det.invalid_record = 1

	DELETE 	prc
	FROM	#epmchdtl prc, #atmtcdet det
	WHERE	prc.invoice_no 	= det.invoice_no
	AND	prc.vendor_code = det.vendor_code
	AND	det.invalid_record = 1

END



------------------------------



DELETE 	hdr
FROM	#atmtchdr hdr, #atmtcdet det
WHERE	hdr.invoice_no = det.invoice_no
AND	hdr.vendor_code = det.vendor_code 
AND	det.invalid_record = 1







DELETE 	det
FROM	#atmtcdet det
WHERE 	det.invoice_no IN (SELECT DISTINCT invoice_no FROM #atmtcdet  WHERE invalid_record = 1 )




IF ((SELECT COUNT(invoice_no) FROM #atmtchdr)  = 0)
BEGIN
	RETURN 0
END
----------------------





DECLARE invoice_details SCROLL CURSOR FOR 
	






		SELECT  hdr.invoice_no, hdr.vendor_code, hdr.source_module
		FROM #atmtchdr hdr
		WHERE	matched = 0

OPEN 	invoice_details

FETCH	invoice_details
-- Rev1.0 	INTO	@invoice_no, @vendor_code, @source_module, @po_no, @part_no, @invoice_qty, @invoice_price, @status 
INTO	@invoice_no, @vendor_code, @source_module

--Rev1.0 SELECT @invoice_no_ant = @invoice_no,  @source_module_ant = @source_module,	@vendor_code_ant = @vendor_code, @part_no_ant = @part_no 
SELECT @vendor_code_ant = @vendor_code




SELECT 	@vo_hold_flag 	= ISNULL(vo_hold_flag,0),@location_code	= location_code,
	@tax_code 	= tax_code,	@terms_code	= terms_code,		@rate_type_home	= rate_type_home,
	@rate_type_oper	= rate_type_oper,	@user_trx_type_code = user_trx_type_code,@posting_code	= posting_code,
	@branch_code	= branch_code,		@vend_class_code = vend_class_code, 	@comment_code	= comment_code,	
	@fob_code	= fob_code,		@terms_code	= terms_code,		@payment_code	= payment_code,
	@attention_name	= attention_name,	@attention_phone = attention_phone,	@code_1099	= code_1099	
FROM 	apvend
WHERE 	vendor_code 	= @vendor_code
	

if ( @voprocs_invoice_taxflag = 1)
	select @tax_code = tmp_tax_code from #tbl_vendorconfig



SELECT 	@precision = curr_precision
FROM	glcurr_vw, #atmtchdr 
WHERE	currency_code 	= nat_cur_code
AND	invoice_no 	= @invoice_no
AND	vendor_code	= @vendor_code

WHILE @@FETCH_STATUS  = 0
BEGIN
	



	
        
        



	IF (@vendor_code_ant != @vendor_code)
	BEGIN
		SELECT 	@vendor_code_ant = @vendor_code			

		SELECT 	@vo_hold_flag 	= ISNULL(vo_hold_flag,0),@po_item_flag	= ISNULL(po_item_flag,0),@location_code	= location_code,
			@tax_code 	= tax_code, @terms_code	= terms_code,		@rate_type_home	= rate_type_home,
			@rate_type_oper	= rate_type_oper,	@user_trx_type_code = user_trx_type_code,@posting_code	= posting_code,
			@branch_code	= branch_code,		@vend_class_code = vend_class_code, 	@comment_code	= comment_code,	
			@fob_code	= fob_code,		@terms_code	= terms_code,		@payment_code	= payment_code,
			@attention_name	= attention_name,	@attention_phone = attention_phone,	@code_1099	= code_1099	
		FROM 	apvend
		WHERE 	vendor_code 	= @vendor_code
	
		
		if ( @voprocs_invoice_taxflag = 1)
			select @tax_code = tmp_tax_code from #tbl_vendorconfig
	END
	
	IF (@source_module = 'PRC')
	BEGIN
		


		EXEC @result = ARGetNextControl_SP 3600, @next_trx OUTPUT, @num OUTPUT 
		
		IF @result != 0
		BEGIN
			RETURN -1

		END
		
		set @mt_ctrl_num = @next_trx
		
		INSERT #epmchhdr (	match_ctrl_num,	vendor_code,		vendor_remit_to,	vendor_invoice_no,date_match,	tolerance_hold_flag,
		tolerance_approval_flag,validated_flag,	vendor_invoice_date,	invoice_receive_date,	apply_date,	aging_date,
		due_date,		discount_date,	amt_net,		amt_discount,		amt_tax,	amt_freight,
		amt_misc,		amt_due,	match_posted_flag,	amt_tax_included,	trx_ctrl_num,	nat_cur_code,
		rate_type_home,		rate_type_oper,	rate_home,		rate_oper,		batch_code,
		org_id	)			
		SELECT 			@next_trx,	@vendor_code,		'',			@invoice_no,	@today,		0,
		0,			1,		date_doc,		date_imported,		date_doc,	date_doc,
		date_doc,		date_discount,	amt_net,		amt_discount,		amt_tax,	amt_freight,
		amt_misc,		0,		1,			0,			'',nat_cur_code,
		@rate_type_home,	@rate_type_oper,1,			1,			'',
		org_id
		FROM	#atmtchdr
		WHERE	invoice_no 	= @invoice_no
		AND	vendor_code	= @vendor_code
		




		UPDATE 	#epmchdtl
		SET 	match_ctrl_num 	= @next_trx
		WHERE	invoice_no 	= @invoice_no
		AND	vendor_code 	= @vendor_code
		




		


		SELECT @sequence_id_match = 0
		
		UPDATE #epmchdtl
		SET sequence_id = @sequence_id_match,
		    @sequence_id_match =  CASE WHEN match_ctrl_num <> @match_ctrl_num THEN 1 ELSE @sequence_id_match + 1 END,
		    @match_ctrl_num = match_ctrl_num
		FROM #epmchdtl
		WHERE match_ctrl_num = @next_trx

		


		EXEC 	@result = apnewnum_sp	4091,	'',	@next_trx OUTPUT
		
		IF (@result != 0)
			RETURN -1

		


		SELECT 	@amt_misc_sum = SUM(amt_misc), @amt_tax_sum = SUM(amt_tax),
			@amt_freight_sum = SUM(amt_freight), @amt_disc_sum = SUM(amt_discount)
		FROM	#atmtcdet
		WHERE	invoice_no = @invoice_no
		AND	vendor_code = @vendor_code


		
		SELECT @apply = @today
		IF @apply > (SELECT period_end_date FROM apco)
		BEGIN
			SELECT @apply = period_end_date FROM apco
		END

		SELECT @match_receiptdate_flag = match_receiptdate_flag, @match_requestdate_flag = match_requestdate_flag
		FROM atco

		
		SELECT @apply = @today
		IF @apply > (SELECT period_end_date FROM apco)
		BEGIN
			SELECT @apply = period_end_date FROM apco
		END
		
		


		INSERT #apinpchg (trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
		po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
		date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
		posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
		comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
		payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
		add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
		amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
		amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
		user_id,	next_serial_id,	attention_name,	attention_phone,intercompany_flag,	company_code,
		cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
		rate_oper,	net_original_amt, org_id, tax_freight_no_recoverable, at_tax_calc_flag )
		SELECT  DISTINCT @next_trx,	4091,		a.vendor_invoice_no,'',		@user_trx_type_code,	'',
		po_ctrl_num = @mt_ctrl_num,'',		'',	@apply ,	a.aging_date,	a.aging_date,		
		a.vendor_invoice_date ,	@today,	
		CASE @match_receiptdate_flag WHEN 1 THEN a.vendor_invoice_date ELSE f.date_imported END,
		CASE @match_requestdate_flag WHEN 1 THEN a.vendor_invoice_date ELSE f.date_imported END,
										0,			a.due_date,		
		@posting_code,	a.vendor_code,	'',		@branch_code,	@vend_class_code,	c.default_aprv_code,		
		@comment_code,	@fob_code,	@terms_code, f.tmp_tax_code
		,	'',			@location_code,
		@payment_code,	0,		0,		0,		0,			@vo_hold_flag,		
		0,		0,		0,		one_time_vend_flag = CASE a.vendor_code	WHEN c.one_time_vend_code THEN 1 ELSE 0 END,
										0,			((a.amt_net - a.amt_freight - a.amt_misc -  a.amt_tax) + a.amt_discount),
		
		a.amt_discount,	a.amt_tax,	a.amt_freight,	a.amt_misc,	a.amt_net,		0.0,		
		
		0.0,		0.0,		0,		0.0,		'',			'',		
		user_id(),	0,		@attention_name,@attention_phone,0,			e.company_code,		
		0,		'',		a.nat_cur_code, @rate_type_home, @rate_type_oper,	1,
		1,		a.amt_net,	a.org_id,	0, f.at_tax_calc_flag
		FROM #epmchhdr a, apco c, glcomp_vw e, #atmtchdr f 
		WHERE a.vendor_invoice_no	= @invoice_no
		AND a.vendor_code 	= @vendor_code
		AND c.company_id 	= e.company_id
		AND a.vendor_invoice_no = f.invoice_no  
		AND a.vendor_code 	= f.vendor_code 
		

		
		

		DELETE #apterm 

		INSERT #apterm ( date_doc, terms_code)
		SELECT	DISTINCT a.date_doc , a.terms_code
		FROM 	#apinpchg a

		EXEC	APGetTermInfo_sp

		UPDATE #apinpchg
		SET 	date_due = t.date_due,
			date_discount = t.date_discount
		FROM 	#apinpchg h
			INNER JOIN #apterm t
			ON h.date_doc = t.date_doc
			AND h.terms_code = t.terms_code


	
IF (@ctrl_rcp = 1)	
	BEGIN		
		
		---Modify the SELECT clause and put 0 in the sequence_id
		---Add the GROUP BY clause
		---Create the #temp_apinpcdt identically of the #apinpcdt
		---In step 1 group the same lines (the lines that are repeated and that does not have to)
		---In step 2 group the lines that are talking of the same item
		
		
		INSERT #apinpcdt(trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	qty_ordered,
		qty_received,   qty_returned,	qty_prev_returned,approval_code,tax_code,	return_code,	code_1099,
		po_ctrl_num,	unit_code,   	unit_price,   	amt_discount,	amt_freight,	amt_tax,	amt_misc,
		amt_extended,   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code,	org_id,amt_nonrecoverable_tax,amt_tax_det   )  
		SELECT 		a.trx_ctrl_num,	4091,  		0,  a.location_code, b.part_no,	0,  		b.qty,  
		b.qty,	
				0,  		0,  		a.approval_code, CASE WHEN cfg.at_tax_calc_flag = 1 THEN cfg.tmp_tax_code ELSE e.tax_code END,  	'',  		@code_1099,  
		b.po_no,  	e.unit_code, 	b.unit_price,  	b.amt_discount,  
			b.amt_freight  ,	
			CASE WHEN (a.at_tax_calc_flag = 0 OR cfg.voprocs_amount_acc_expense = 0) THEN 0.0 ELSE b.amt_tax END , 
			b.amt_misc ,
		ROUND(( b.unit_price * b.qty ), @precision), 
				b.amt_tax,  	@today,  	e.account_code, e.account_code,  '',  		e.item_desc,  
		0,  		c.company_id,	0,  		0,  		(select company_code from glcomp_vw where e.company_id =    glcomp_vw.company_id) ,
												'', 		reference_code = CASE ISNULL(e.reference_code, '')  WHEN '' THEN ' ' ELSE e.reference_code  END,  
		new_reference_code = CASE ISNULL(e.reference_code, '') WHEN '' THEN ' '  ELSE e.reference_code  END, dbo.IBOrgbyAcct_fn(e.account_code),0,0  
		FROM #apinpchg a, #atmtcdet b, glcomp_vw c, epinvdtl e , epinvhdr h
			, #tbl_vendorconfig cfg
		WHERE a.doc_ctrl_num 	= b.invoice_no
		AND a.company_code 	= c.company_code
		AND b.part_no 		= e.item_code
		AND b.invoice_no 	= @invoice_no -- Rev1.0
		
		AND h.receipt_ctrl_num 	= e.receipt_ctrl_num
		AND upper(h.po_ctrl_num) = upper(b.po_no)
		AND cfg.vendor_code = a.vendor_code
		GROUP BY a.trx_ctrl_num,	b.sequence_id,  a.location_code, b.part_no,	b.qty,  
		e.qty_received,	a.approval_code, a.tax_code,  	b.po_no,  	e.unit_code, 	b.unit_price,  	
		b.amt_tax,  	e.account_code, e.account_code,  e.item_desc,  e.company_id,	
		e.reference_code, cfg.at_tax_calc_flag, cfg.tmp_tax_code,
		e.tax_code, b.amt_discount, b.amt_freight, cfg.voprocs_amount_acc_expense,
		a.at_tax_calc_flag, b.amt_misc, c.company_id

		
		INSERT #apinpcdt(trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	qty_ordered,
		qty_received,   qty_returned,	qty_prev_returned,approval_code,tax_code,	return_code,	code_1099,
		po_ctrl_num,	unit_code,   	unit_price,   	amt_discount,	amt_freight,	amt_tax,	amt_misc,
		amt_extended,   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code   ) 
		SELECT trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	SUM(qty_ordered),
		SUM(qty_received),   SUM(qty_returned),	SUM(qty_prev_returned),approval_code,tax_code,	return_code,	code_1099,
		po_ctrl_num,	unit_code,   	unit_price,   	SUM(amt_discount),	SUM(amt_freight),	SUM(amt_tax),	SUM(amt_misc),
		SUM(amt_extended),   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code
		FROM #temp_apinpcdt
		GROUP BY  trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	approval_code,
		tax_code,	return_code,	code_1099,po_ctrl_num,	unit_code,   	unit_price,   	calc_tax,   	date_entered,   
		gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code

		DELETE 	#temp_apinpcdt		
		
			
	END

ELSE	
	BEGIN
		
		---Modify the SELECT clause and put 0 in the sequence_id
		---Add the GROUP BY clause
		---Create the #temp_apinpcdt identically of the #apinpcdt
		---In step 1 group the same lines (the lines that are repeated and that does not have to)
		---In step 2 group the lines that are talking of the same item
		
		
		INSERT #apinpcdt(trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	qty_ordered,
		qty_received,   qty_returned,	qty_prev_returned,approval_code,tax_code,	return_code,	code_1099,
		po_ctrl_num,	unit_code,   	unit_price,   	amt_discount,	amt_freight,	amt_tax,	amt_misc,
		amt_extended,   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code,	org_id,amt_nonrecoverable_tax,amt_tax_det   )  
		SELECT 		a.trx_ctrl_num,	4091,  		0,  a.location_code, b.part_no,	0,  		e.qty_received,  
		e.qty_received,	
				0,  		0,  		a.approval_code, CASE WHEN cfg.at_tax_calc_flag = 1 THEN cfg.tmp_tax_code ELSE e.tax_code END,  	'',  		@code_1099,  
		b.po_no,  	e.unit_code, 	b.unit_price,  	b.amt_discount,  
			b.amt_freight  ,	
			CASE WHEN (a.at_tax_calc_flag = 0 OR cfg.voprocs_amount_acc_expense = 0) THEN 0.0 ELSE b.amt_tax END , 
			b.amt_misc ,
		ROUND(( b.unit_price * e.qty_received ), @precision), 
				b.amt_tax,  	@today,  	e.account_code, e.account_code,  '',  		e.item_desc,  
		0,  		c.company_id,	0,  		0,  		(select company_code from glcomp_vw where e.company_id =    glcomp_vw.company_id) ,
												'', 		reference_code = CASE ISNULL(e.reference_code, '')  WHEN '' THEN ' ' ELSE e.reference_code  END,  
		new_reference_code = CASE ISNULL(e.reference_code, '') WHEN '' THEN ' '  ELSE e.reference_code  END, dbo.IBOrgbyAcct_fn(e.account_code),0,0  
		FROM #apinpchg a, #atmtcdet b, glcomp_vw c, epinvdtl e , epinvhdr h
			, #tbl_vendorconfig cfg
		WHERE a.doc_ctrl_num 	= b.invoice_no
		AND a.company_code 	= c.company_code
		AND b.part_no 		= e.item_code
		AND b.invoice_no 	= @invoice_no -- Rev1.0
		
		AND h.receipt_ctrl_num 	= e.receipt_ctrl_num
		AND upper(h.po_ctrl_num) = upper(b.po_no)
		AND cfg.vendor_code = a.vendor_code
		GROUP BY a.trx_ctrl_num,	b.sequence_id,  a.location_code, b.part_no,	b.qty,  
		e.qty_received,	a.approval_code, a.tax_code,  	b.po_no,  	e.unit_code, 	b.unit_price,  	
		b.amt_tax,  	e.account_code, e.account_code,  e.item_desc,  e.company_id,	
		e.reference_code, cfg.at_tax_calc_flag, cfg.tmp_tax_code,
		e.tax_code, b.amt_discount, b.amt_freight, cfg.voprocs_amount_acc_expense,
		a.at_tax_calc_flag, b.amt_misc, c.company_id

		
		INSERT #apinpcdt(trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	qty_ordered,
		qty_received,   qty_returned,	qty_prev_returned,approval_code,tax_code,	return_code,	code_1099,
		po_ctrl_num,	unit_code,   	unit_price,   	amt_discount,	amt_freight,	amt_tax,	amt_misc,
		amt_extended,   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code   ) 
		SELECT trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	SUM(qty_ordered),
		SUM(qty_received),   SUM(qty_returned),	SUM(qty_prev_returned),approval_code,tax_code,	return_code,	code_1099,
		po_ctrl_num,	unit_code,   	unit_price,   	SUM(amt_discount),	SUM(amt_freight),	SUM(amt_tax),	SUM(amt_misc),
		SUM(amt_extended),   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code
		FROM #temp_apinpcdt
		GROUP BY  trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	approval_code,
		tax_code,	return_code,	code_1099,po_ctrl_num,	unit_code,   	unit_price,   	calc_tax,   	date_entered,   
		gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code

		DELETE 	#temp_apinpcdt		
		
			
	
		EXEC appgetstring_sp 'STR_DETAIL_BY_APMATCH', @str_msg_at  OUT

		INSERT #apinpcdt(trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	qty_ordered,
		qty_received,   qty_returned,	qty_prev_returned,approval_code,tax_code,	return_code,	code_1099,
		po_ctrl_num,	unit_code,   	unit_price,   	amt_discount,	amt_freight,	amt_tax,	amt_misc,
		amt_extended,   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code   )  

		SELECT DISTINCT  a.trx_ctrl_num,	4091,  		0,  a.location_code, d.part_no,	0,  	( d.qty_invoiced - d.qty_received ),  
		( d.qty_invoiced - d.qty_received ),	
				0,  		0,  		a.approval_code, a.tax_code,  	'',  		@code_1099,  
		b.po_no,  	e.unit_code, 	b.unit_price,  	0.0,		0.0,		0.0,		0.0,
		ROUND(( b.unit_price * ( d.qty_invoiced - d.qty_received )), @precision),
				b.amt_tax,  	@today,  	e.account_code, e.account_code,  '',  		@str_msg_at,  
		0,  		e.company_id,	0,  		0,  		(select company_code from glcomp_vw where e.company_id =    glcomp_vw.company_id) , 
														'', reference_code = CASE ISNULL(e.reference_code, '')  WHEN '' THEN ' ' ELSE e.reference_code  END,  
		new_reference_code = CASE ISNULL(e.reference_code, '') WHEN '' THEN ' '  ELSE e.reference_code  END  
		FROM #apinpchg a, #atmtcdet b, glcomp_vw c, epinvdtl e , epinvhdr h, #ctrlpo d
		WHERE  d.part_no	= b.part_no
		AND upper(d.po_no)	= upper(h.po_ctrl_num)
		AND ( d.qty_invoiced - d.qty_received ) > 0
		GROUP BY a.trx_ctrl_num,a.location_code, d.part_no,	a.approval_code, a.tax_code,  	b.po_no,  	e.unit_code, 	
				b.unit_price,  	b.amt_tax,  	e.account_code, e.account_code,  e.company_id,	 e.reference_code ,d.qty_invoiced ,
				d.qty_received
	END		
			
		INSERT #apinpage ( trx_ctrl_num,trx_type,	sequence_id,	date_applied,	date_due,	date_aging,	amt_due	 )
		SELECT 		 trx_ctrl_num,  trx_type, 	1,	 	date_applied,	date_due,   	date_aging,	amt_net 
		FROM #apinpchg 
		WHERE doc_ctrl_num = @invoice_no -- Rev1.0


		


		UPDATE #apinpchg SET intercompany_flag = 1
		FROM #apinpchg h INNER JOIN #apinpcdt d
			ON h.trx_ctrl_num = d.trx_ctrl_num
			AND h.trx_type = d.trx_type
		WHERE company_code <> rec_company_code

		
		


	END	
	ELSE IF (@source_module = 'ADM' AND @adm_installed = 1)
	BEGIN
	
		UPDATE adm_next_match_no 
		SET 	last_no = last_no + 1 
		
		SELECT @adm_next_match_no = last_no FROM adm_next_match_no 
		
		set @mt_ctrl_num = @adm_next_match_no 									

		SELECT @apply = @today											
		IF @apply > (SELECT period_end_date FROM apco)								
		BEGIN													
			SELECT @apply = period_end_date FROM apco							
		END

		


		SELECT 	@amt_misc_sum = SUM(amt_misc), @amt_tax_sum = SUM(amt_tax),
			@amt_freight_sum = SUM(amt_freight), @amt_disc_sum = SUM(amt_discount)
		FROM	#atmtcdet
		WHERE	invoice_no = @invoice_no
		AND	vendor_code = @vendor_code


		INSERT #adm_pomchchg (match_ctrl_int,		vendor_code,		vendor_remit_to,vendor_invoice_no,	date_match,	printed_flag,
		vendor_invoice_date,	invoice_receive_date,	apply_date,		aging_date,	due_date,	discount_date,	
		amt_net,		amt_discount,		amt_tax,		amt_freight,	amt_misc,	amt_due,
		match_posted_flag,	nat_cur_code,		amt_tax_included,	trx_type,	po_no,		location,	
		amt_gross,		process_group_num,	rate_type_home,		rate_type_oper,	curr_factor,	oper_factor,
		tax_code,		terms_code,		org_id		)
		SELECT 			@adm_next_match_no,	vendor_code,		'',		invoice_no,	getdate(), 		0,	
		date_doc, 		date_imported,		date_doc,		date_doc,	date_doc,	date_discount,
		amt_net,		amt_discount,		amt_tax,		amt_freight,	amt_misc,	0,	
		1,			nat_cur_code,		0,			4091,		0,		@location_code,
		((amt_net - (amt_freight + @amt_freight_sum) - (amt_misc + @amt_misc_sum) - (amt_tax + @amt_tax_sum)) + (amt_discount + @amt_disc_sum)), 
					'',			@rate_type_home,	@rate_type_oper,1,		1,
		@tax_code,		@terms_code,		org_id
		FROM	#atmtchdr
		WHERE	invoice_no 	= @invoice_no
		AND	vendor_code	= @vendor_code	
		
	
	
		UPDATE 	#adm_pomchcdt
		SET	match_ctrl_int	= @adm_next_match_no
		WHERE	invoice_no	= @invoice_no
		AND	vendor_code	= @vendor_code
		
	

		


		EXEC 	@result = apnewnum_sp	4091,	'',	@next_trx OUTPUT

		IF (@result != 0)
			RETURN -1
			
		


		SELECT @sequence_id_match = 0

		UPDATE #adm_pomchcdt
		SET match_line_num = @sequence_id_match,
		    @sequence_id_match =  CASE WHEN match_ctrl_int <> @match_ctrl_int THEN 1 ELSE @sequence_id_match + 1 END,
		    @match_ctrl_int = match_ctrl_int
		FROM #adm_pomchcdt
		WHERE match_ctrl_int = @adm_next_match_no


		INSERT #apinpchg (trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
		po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
		date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
		posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
		comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
		payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
		add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
		amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
		amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
		user_id,	next_serial_id,	attention_name,	attention_phone,intercompany_flag,	company_code,
		cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
		rate_oper,	net_original_amt, org_id,	tax_freight_no_recoverable, at_tax_calc_flag )
		SELECT  DISTINCT @next_trx,	4091,		a.vendor_invoice_no,'',		@user_trx_type_code,	'',
		po_ctrl_num = @mt_ctrl_num,'',		'',	@apply ,	a.aging_date,	a.aging_date,		
		a.vendor_invoice_date ,	@today,	
		CASE @match_receiptdate_flag WHEN 1 THEN a.vendor_invoice_date ELSE f.date_imported END,
		CASE @match_requestdate_flag WHEN 1 THEN a.vendor_invoice_date ELSE f.date_imported END,
										0,			a.due_date,		
		@posting_code,	a.vendor_code,	'',		@branch_code,	@vend_class_code,	c.default_aprv_code,		
		@comment_code,	@fob_code,	@terms_code, f.tmp_tax_code
		,	'',			@location_code,
		@payment_code,	0,		0,		0,		0,			@vo_hold_flag,		
		0,		0,		0,		one_time_vend_flag = CASE a.vendor_code	WHEN c.one_time_vend_code THEN 1 ELSE 0 END,
										0,			a.amt_gross, 
		
		a.amt_discount,	a.amt_tax,	a.amt_freight,	a.amt_misc,	a.amt_net,		0.0,		
		
		0.0,		0.0,		0,		0.0,		'',			'',		
		user_id(),	0,		@attention_name,@attention_phone,0,			e.company_code,		
		0,		'',		a.nat_cur_code, @rate_type_home, @rate_type_oper,	1,
		1,		a.amt_net,	a.org_id,	0, f.at_tax_calc_flag
		FROM #adm_pomchchg a, apco c, glcomp_vw e, #atmtchdr f 
		WHERE a.vendor_invoice_no	= @invoice_no
		AND a.vendor_code 	= @vendor_code
		AND c.company_id 	= e.company_id
		AND a.vendor_invoice_no = f.invoice_no  
		AND a.vendor_code 	= f.vendor_code 
		




		

		DELETE #apterm 

		INSERT #apterm ( date_doc, terms_code)
		SELECT	DISTINCT a.date_doc , a.terms_code
		FROM 	#apinpchg a

		EXEC	APGetTermInfo_sp

		UPDATE #apinpchg
		SET 	date_due = t.date_due,
			date_discount = t.date_discount
		FROM 	#apinpchg h
			INNER JOIN #apterm t
			ON h.date_doc = t.date_doc
			AND h.terms_code = t.terms_code

		
		INSERT #apinpcdt(trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	qty_ordered,
		qty_received,   qty_returned,	qty_prev_returned,approval_code,tax_code,	return_code,	code_1099,
		po_ctrl_num,	unit_code,   	unit_price,   	amt_discount,	amt_freight,	amt_tax,	amt_misc,
		amt_extended,   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
		serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
		new_reference_code,org_id,amt_nonrecoverable_tax,amt_tax_det   )  
		SELECT 		a.trx_ctrl_num,	4091,  		b.sequence_id,  a.location_code, b.part_no,	0,  CASE WHEN (@ctrl_rcp = 1) THEN b.qty ELSE e.quantity END,  
		CASE WHEN (@ctrl_rcp = 1) THEN b.qty ELSE e.quantity END,	
				0,  		0,  		a.approval_code, a.tax_code,  	'',  		@code_1099,             
		b.po_no,  	e.unit_measure,	b.unit_price,  
			b.amt_discount ,  
			b.amt_freight ,	
			CASE WHEN (a.at_tax_calc_flag = 0 OR cfg.voprocs_amount_acc_expense = 0) THEN 0.0 ELSE b.amt_tax END , 
			b.amt_misc ,
		ROUND(( b.unit_price * e.quantity ), @precision), 
				b.amt_tax,  	@today,  	e.account_no, 	e.account_no,  '',  		'',  
		0,  		c.company_id,	0,  		0,  		c.company_code, c.company_code, reference_code = CASE ISNULL(f.reference_code, '')  WHEN '' THEN ' ' ELSE f.reference_code  END,  
		new_reference_code = CASE ISNULL(f.reference_code, '') WHEN '' THEN ' '  ELSE f.reference_code  END, dbo.IBOrgbyAcct_fn(e.account_no),0,0
		FROM #apinpchg a, #atmtcdet b, glcomp_vw c, receipts e, pur_list f 
			, #tbl_vendorconfig cfg
		WHERE a.doc_ctrl_num 	= b.invoice_no
		AND a.vendor_code 	= b.vendor_code
		AND a.doc_ctrl_num 	= @invoice_no
		AND a.vendor_code 	= @vendor_code
		


		AND a.company_code 	= c.company_code
		AND b.part_no 		= e.part_no
		AND b.po_no 		= e.po_no
		AND b.part_no 		= f.part_no 
		AND b.po_no 		= f.po_no 
		AND cfg.vendor_code = a.vendor_code


		INSERT #apinpage ( trx_ctrl_num,trx_type,	sequence_id,	date_applied,	date_due,	date_aging,	amt_due	 )
		SELECT 		 trx_ctrl_num,  trx_type, 	1,	 	date_applied,	date_due,   	date_aging,	amt_net 
		FROM #apinpchg 
		WHERE	doc_ctrl_num 	= @invoice_no
		AND 	vendor_code 	= @vendor_code
		
		

	END

	





	

	UPDATE 	hdr
	SET	hdr.status = 'M',
		hdr.error_desc ='',
		hdr.date_posted = @today
	FROM	atmtchdr hdr
	WHERE	hdr.invoice_no = @invoice_no
	AND 	hdr.vendor_code = @vendor_code
	



	DELETE 	atmtcerr
	WHERE	invoice_no = @invoice_no
	AND 	vendor_code = @vendor_code
	



	UPDATE 	#atmtcdet
	SET	matched = 1
	WHERE	invoice_no = @invoice_no
	AND 	vendor_code = @vendor_code

	







	












				

	

	



	


	SELECT 	@precision = curr_precision
	FROM	glcurr_vw , #atmtchdr 
	WHERE	currency_code 	= nat_cur_code
	AND	invoice_no 	= @invoice_no
	AND	vendor_code	= @vendor_code

	
	FETCH invoice_details
	-- Rev 1.0 INTO	@invoice_no, @vendor_code, @source_module--, @po_no, @part_no, @invoice_qty, @invoice_price, @status 
	INTO	@invoice_no, @vendor_code, @source_module 
END 

CLOSE invoice_details
DEALLOCATE invoice_details


select vendor_code,invoice_no,min(po_no) as PO_num
into	#temp_PO_num
from 	#atmtcdet
group by vendor_code,invoice_no









DROP TABLE #temp_PO_num





SELECT @sequence_id = 0

UPDATE #apinpcdt
SET sequence_id = @sequence_id,
    @sequence_id =  CASE WHEN trx_ctrl_num <> @trx_ctrl_num THEN 1 ELSE @sequence_id + 1 END,
    @trx_ctrl_num = trx_ctrl_num
FROM #apinpcdt




EXEC ATAPMatchCreateTax_sp 0



































BEGIN TRANSACTION SAVING_DATA

SELECT @batch_mode = 0, @vendor_code = ''

SELECT @batch_mode = ISNULL(batch_proc_flag,0)
FROM 	apco

IF (@batch_mode = 1)
BEGIN
	SELECT @company_code = company_code 
	FROM 	glco
	
	SELECT @start_user_id = user_id()

	DECLARE invoice_header SCROLL CURSOR FOR 
		SELECT DISTINCT vendor_code, org_id, hold_flag 
		FROM	#apinpchg
		
	OPEN 	invoice_header

	FETCH	invoice_header
	INTO	@vendor_code, @org_id, @vo_hold_flag 
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @batch_code = NULL

		SELECT @actual_number = COUNT(trx_ctrl_num), @actual_total = SUM(amt_net)
		FROM	#apinpchg
		WHERE	vendor_code = @vendor_code
		AND	org_id = @org_id 
		GROUP BY vendor_code, org_id 

		EXEC appgetstring_sp 'STR_AUTOMATE_VOUCHER', @str_msg_at  OUT

		EXEC	@result = apnxtbat_sp	 4000, '',	4010,	@start_user_id,	@today,	@company_code,	@batch_code	OUTPUT,	
			@str_msg_at, @org_id 

		


		UPDATE	batchctl
		SET	actual_number = @actual_number,	actual_total = @actual_total,	hold_flag = @vo_hold_flag
		WHERE	batch_ctrl_num = @batch_code

		UPDATE 	#apinpchg
		SET 	batch_code = @batch_code
		WHERE	vendor_code = @vendor_code
		AND 	org_id = @org_id 
	
		FETCH	invoice_header
		INTO	@vendor_code, @org_id, @vo_hold_flag 

	END

	CLOSE invoice_header
	DEALLOCATE invoice_header

END

INSERT  epmchhdr (		match_ctrl_num,		vendor_code,	vendor_remit_to,	vendor_invoice_no,	date_match,	tolerance_hold_flag,
				tolerance_approval_flag,validated_flag,	vendor_invoice_date,	invoice_receive_date,	apply_date,	aging_date,
				due_date,		discount_date,	amt_net,		amt_discount,		amt_tax,	amt_freight,
				amt_misc,		amt_due,	match_posted_flag,	amt_tax_included,	trx_ctrl_num,	nat_cur_code,
				rate_type_home,		rate_type_oper,	rate_home,		rate_oper,		batch_code,
				org_id	)
SELECT 				match_ctrl_num,		vendor_code,	vendor_remit_to,	vendor_invoice_no,	date_match,	tolerance_hold_flag,
				tolerance_approval_flag,validated_flag,	vendor_invoice_date,	invoice_receive_date,	apply_date,	aging_date,
				due_date,		discount_date,	amt_net,		amt_discount,		amt_tax,	amt_freight,
				amt_misc,		amt_due,	match_posted_flag,	amt_tax_included,	trx_ctrl_num,	nat_cur_code,
				rate_type_home,		rate_type_oper,	rate_home,		rate_oper,		batch_code,
				org_id	
FROM #epmchhdr

IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END


INSERT epmchdtl (	match_dtl_key,		match_ctrl_num,		sequence_id,		po_ctrl_num,		po_sequence_id,			
			receipt_ctrl_num,	receipt_dtl_key,	account_code,		reference_code,		company_id,		
			qty_received,		qty_invoiced,		qty_prev_invoiced,	amt_prev_invoiced,	unit_price,
			invoice_unit_price,	tolerance_hold_flag,	match_posted_flag,	tax_code,		amt_tax,			
			amt_tax_included,	calc_tax	)
SELECT 			match_dtl_key,		match_ctrl_num,		sequence_id,		po_ctrl_num,		po_sequence_id,			
			receipt_ctrl_num,	receipt_dtl_key,	account_code,		reference_code,		company_id,		
			qty_received,		qty_invoiced,		qty_prev_invoiced,	amt_prev_invoiced,	unit_price,
			invoice_unit_price,	tolerance_hold_flag,	match_posted_flag,	isnull(tax_code,(select tax_code from apco)),	amt_tax,			
			amt_tax_included,	calc_tax
FROM	#epmchdtl
IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END



IF (@adm_installed = 1 )
BEGIN
       
	INSERT adm_pomchchg (match_ctrl_int,	vendor_code,		vendor_remit_to,	vendor_invoice_no,	date_match,	printed_flag,
			vendor_invoice_date,	invoice_receive_date,	apply_date,		aging_date,		due_date,	discount_date,	
			amt_net,		amt_discount,		amt_tax,		amt_freight,		amt_misc,	amt_due,
			match_posted_flag,	nat_cur_code,		amt_tax_included,	trx_type,		po_no,		location,	
			amt_gross,		process_group_num,	rate_type_home,		rate_type_oper,		curr_factor,	oper_factor,
			tax_code,		terms_code,		one_time_vend_ind,	pay_to_addr1,		pay_to_addr2,	pay_to_addr3,	
			pay_to_addr4,		pay_to_addr5,		pay_to_addr6,		attention_name,		attention_phone	)
	SELECT 		match_ctrl_int,		vendor_code,		vendor_remit_to,	vendor_invoice_no,	date_match,	printed_flag,
			dateadd( day,  vendor_invoice_date - 693596, '01/01/1900'),	
						dateadd( day,invoice_receive_date - 693596, '01/01/1900'),
									dateadd( day,apply_date - 693596, '01/01/1900'),	
												dateadd( day,aging_date - 693596, '01/01/1900'),		
															dateadd( day,due_date - 693596, '01/01/1900'),	
																	dateadd( day,discount_date - 693596, '01/01/1900'),
			amt_net,		amt_discount,		amt_tax,		amt_freight,		amt_misc,	amt_due,
			match_posted_flag,	nat_cur_code,		amt_tax_included,	trx_type,		po_no,		location,	
			amt_gross,		process_group_num,	rate_type_home,		rate_type_oper,		curr_factor,	oper_factor,
			tax_code,		terms_code,		' ',			' ',			' ',		' ',
			' ',			' ',			' ',			' ',			' '
	FROM	#adm_pomchchg
	

	IF @@ERROR != 0
	BEGIN
		ROLLBACK TRANSACTION SAVING_DATA
		RETURN 1
	END

	INSERT adm_pomchcdt(	match_ctrl_int,		match_line_num,		po_ctrl_num,		po_ctrl_int,		po_line_num,
				gl_acct,		qty_ordered,		unit_price,		match_unit_price,	qty_invoiced,
				match_posted_flag,	conv_factor,		part_no,		item_desc,		gl_ref_code,
				tax_code,		amt_tax,		amt_tax_included,	calc_tax,		receipt_no,
				location,		nat_curr,		oper_factor,		curr_factor,		oper_cost,		
				curr_cost,		misc)
	SELECT 			match_ctrl_int,		match_line_num,		po_ctrl_num,		po_ctrl_int,		po_line_num,
				gl_acct,		qty_ordered,		unit_price,		match_unit_price,	qty_invoiced,
				match_posted_flag,	conv_factor,		part_no,		item_desc,		gl_ref_code,
				tax_code,		amt_tax,		amt_tax_included,	calc_tax,		receipt_no,
				location,		nat_curr,		oper_factor,		curr_factor,		oper_cost,		
				curr_cost,		misc
	FROM #adm_pomchcdt

	IF @@ERROR != 0
	BEGIN
		ROLLBACK TRANSACTION SAVING_DATA
		RETURN 1
	END

END 


UPDATE d 
SET d.amt_discount = ROUND(d.amt_discount, isnull(g.curr_precision,1.0)), 
d.amt_freight = ROUND(d.amt_freight, isnull(g.curr_precision,1.0)),
d.amt_tax = CASE WHEN (x.voprocs_amount_acc_expense = 0) THEN ROUND(d.amt_tax, isnull(g.curr_precision,1.0)) ELSE ROUND(d.amt_tax_det, isnull(g.curr_precision,1.0)) END,
d.amt_misc = ROUND(d.amt_misc, isnull(g.curr_precision,1.0)), 
d.amt_extended = ROUND(d.unit_price * qty_received, isnull(g.curr_precision,1.0)) ,
d.calc_tax = ROUND(d.calc_tax, isnull(g.curr_precision,1.0)), d.amt_nonrecoverable_tax = ROUND(d.amt_nonrecoverable_tax, isnull(g.curr_precision,1.0)), 
d.amt_tax_det = ROUND(d.amt_tax_det, isnull(g.curr_precision,1.0))
FROM #apinpcdt d
	INNER JOIN #apinpchg h ON ( h.trx_ctrl_num = d.trx_ctrl_num AND h.trx_type = d.trx_type )
	INNER JOIN #tbl_vendorconfig x ON ( x.vendor_code = h.vendor_code )
	LEFT OUTER JOIN glcurr_vw g (nolock) ON (h.nat_cur_code = g.currency_code)


CREATE TABLE #cdt
(
	trx_ctrl_num	varchar(16),		
	sequence_id	int,
	price		float,
	amt_discount	float,
	weight		float,
        amt_freight FLOAT
) 
INSERT INTO #cdt
    SELECT d.trx_ctrl_num, 
           MAX(sequence_id),
           SUM(round(d.amt_extended, isnull(g.curr_precision,1.0))+round(d.amt_nonrecoverable_tax, isnull(g.curr_precision,1.0))) price,        
           SUM(round(d.amt_discount, isnull(g.curr_precision,1.0))) amt_discount,
           SUM(round(d.amt_misc, isnull(g.curr_precision,1.0))) weight ,
           SUM(round(d.amt_freight, isnull(g.curr_precision,1.0))) amt_freight
            FROM #apinpcdt d
		INNER JOIN #apinpchg h ON ( h.trx_ctrl_num = d.trx_ctrl_num AND h.trx_type = d.trx_type )
		LEFT OUTER JOIN glcurr_vw g (nolock) ON (h.nat_cur_code = g.currency_code)
            GROUP BY d.trx_ctrl_num

SELECT     i.[trx_ctrl_num],
    ROUND(SUM(ISNULL(i.[amt_final_tax],0)), 2) [amt_tax],
    ROUND(SUM(ISNULL(t.[tax_included_flag],0) * ISNULL(i.[amt_final_tax],0) ),2) [amt_tax_included]
INTO #tmp_aptaxincluded
  FROM     #apinptax i
	INNER JOIN [aptxtype] t
		ON i.tax_type_code = t.tax_type_code
   WHERE ISNULL(t.recoverable_flag,0) =1
 GROUP BY i.[trx_ctrl_num]

UPDATE h
SET h.amt_gross = cdt.price - tax.amt_tax_included,
h.amt_net = (cdt.price - tax.amt_tax_included + tax.amt_tax - h.amt_discount + h.amt_freight + h.amt_misc),
h.amt_tax_included = tax.amt_tax_included,
h.amt_due =(cdt.price - tax.amt_tax_included + tax.amt_tax - h.amt_discount + h.amt_freight + h.amt_misc),
h.amt_tax = tax.amt_tax
FROM #apinpchg h
INNER JOIN #cdt cdt ON (h.trx_ctrl_num = cdt.trx_ctrl_num)
INNER JOIN #tmp_aptaxincluded tax ON  (h.trx_ctrl_num = tax.trx_ctrl_num)
WHERE h.at_tax_calc_flag <> 1 

UPDATE h
SET h.amt_gross = cdt.price,
h.amt_net = (cdt.price + h.amt_tax - h.amt_discount + h.amt_freight + h.amt_misc),
h.amt_due = (cdt.price + h.amt_tax - h.amt_discount + h.amt_freight + h.amt_misc)
FROM #apinpchg h
INNER JOIN #cdt cdt ON (h.trx_ctrl_num = cdt.trx_ctrl_num)
WHERE h.at_tax_calc_flag = 1

drop table #tmp_aptaxincluded
drop table #cdt

update a SET a.amt_due = h.amt_net
from #apinpage a, #apinpchg h
where a.trx_ctrl_num = h.trx_ctrl_num and a.trx_type = h.trx_type


INSERT apinpchg (	trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
			po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
			date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
			posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
			comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
			payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
			add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
			amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
			amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
			user_id,	next_serial_id,	attention_name,	attention_phone,intercompany_flag,	company_code,
			cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
			rate_oper,	net_original_amt, pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,		
			pay_to_addr5,	pay_to_addr6,	org_id,		tax_freight_no_recoverable)
SELECT 			trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
			po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
			date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
			posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
			ISNULL(comment_code,''),	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
			payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
			add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
			amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
			amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
			user_id,	next_serial_id,	attention_name,	attention_phone,intercompany_flag,	company_code,
			cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
			rate_oper,	net_original_amt, ' ',		' ',		' ',			' ',
			' ',		' ',		org_id,		tax_freight_no_recoverable 
FROM #apinpchg

IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END




	

	INSERT INTO epmchpsthdr(process_ctrl_num,batch_code,match_ctrl_num,trx_ctrl_num,vendor_code,doc_ctrl_num,amt_due,symbol)
	SELECT @process_ctrl_num,
		ISNULL(a.batch_code, ' '),
		a.po_ctrl_num,
		a.trx_ctrl_num,
		a.vendor_code,
		a.doc_ctrl_num,
		a.amt_due,
		b.symbol
	FROM #apinpchg a, glcurr_vw b 
	WHERE a.nat_cur_code = b.currency_code



IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END

INSERT apinpcdt (	trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	qty_ordered,
			qty_received,   qty_returned,	qty_prev_returned,approval_code,tax_code,	return_code,	code_1099,
			po_ctrl_num,	unit_code,   	unit_price,   	amt_discount,	amt_freight,	amt_tax,	amt_misc,
			amt_extended,   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
			serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
			new_reference_code,	org_id,amt_nonrecoverable_tax,amt_tax_det   )
SELECT 			trx_ctrl_num,	trx_type,   	sequence_id,  	location_code,	item_code,	bulk_flag,	qty_ordered,
			qty_received,   qty_returned,	qty_prev_returned,approval_code,tax_code,	return_code,	ISNULL(code_1099,''),
			po_ctrl_num,	unit_code,   	unit_price,   	amt_discount,	amt_freight,	amt_tax,	amt_misc,
			amt_extended,   calc_tax,   	date_entered,   gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,
			serial_id,   	company_id,   	iv_post_flag,   po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code,   
			new_reference_code, org_id,amt_nonrecoverable_tax,amt_tax_det
FROM #apinpcdt


IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END

INSERT apinpage (trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,	date_aging,	amt_due)
SELECT 		trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,	date_aging,	amt_due
FROM	#apinpage

IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END

INSERT apinptax(trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,	amt_tax,	amt_final_tax)
SELECT 		trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,	amt_tax,	amt_final_tax
FROM	#apinptax

INSERT apinptaxdtl(trx_ctrl_num,	sequence_id,trx_type,	tax_sequence_id,	detail_sequence_id,			
		   tax_type_code,	amt_taxable,amt_gross,	amt_tax,amt_final_tax,	recoverable_flag,	account_code) 
SELECT 		   trx_ctrl_num,	sequence_id,trx_type,	tax_sequence_id,	detail_sequence_id,
		   tax_type_code,	amt_taxable,amt_gross,	amt_tax,amt_final_tax,	recoverable_flag,	account_code
FROM	#apinptaxdtl														

IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END


UPDATE	dtl
SET 	dtl.qty_invoiced = dpo.qty_invoiced					
FROM	#atmtcdet at_det, epinvhdr hdr,  epinvdtl dtl, #ctrlpo dpo		
WHERE 	hdr.receipt_ctrl_num 	= dtl.receipt_ctrl_num 	
	AND at_det.vendor_code 	= hdr.vendor_code
	AND dpo.po_no 		= hdr.po_ctrl_num				
	AND dpo.part_no 	= dtl.item_code					

IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END

UPDATE	dtl
SET 	dtl.invoiced_full_flag = 1
FROM	#atmtcdet at_det, epinvhdr hdr,  epinvdtl dtl
WHERE 	hdr.receipt_ctrl_num 	= dtl.receipt_ctrl_num 	
	AND at_det.vendor_code 	= hdr.vendor_code
	AND at_det.po_no 	= hdr.po_ctrl_num
	AND at_det.part_no 	= dtl.item_code
	AND dtl.qty_invoiced 	>= dtl.qty_received


IF @@ERROR != 0
BEGIN
	ROLLBACK TRANSACTION SAVING_DATA
	RETURN 1
END


COMMIT TRANSACTION SAVING_DATA

DROP TABLE #ctrlpo 

DROP TABLE #atmtchdr
DROP TABLE #atmtcdet
DROP TABLE #epmchhdr
DROP TABLE #epmchdtl
DROP TABLE #adm_pomchchg
DROP TABLE #adm_pomchcdt
DROP TABLE #apinpchg
DROP TABLE #apinpcdt
DROP TABLE #apinpage
DROP TABLE #apinptax
DROP TABLE #mtinptax
DROP TABLE #apinptaxdtl 


RETURN 0 




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ATAPMatchProcess_sp] TO [public]
GO
