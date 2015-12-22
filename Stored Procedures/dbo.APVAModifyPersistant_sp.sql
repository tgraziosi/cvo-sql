SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APVAModifyPersistant_sp]
											@batch_ctrl_num		varchar(16),
											@client_id 			varchar(20),
											@user_id			smallint,  
											@debug_level		smallint = 0
AS

DECLARE
	@errbuf				varchar(100),
	@result				int,
	@current_date		int,
	@company_code	varchar(8),
	@voucher_no	varchar(16)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvamp.cpp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "


EXEC appdate_sp	@current_date OUTPUT






EXEC @result = APVAUPActivity_sp  	@batch_ctrl_num, 
									@client_id,
									@user_id,
	                                @debug_level
IF(@result != 0 )
	RETURN @result

DELETE #apvahisx_work
FROM aphistrx a, #apvahisx_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num

INSERT	aphistrx(
		trx_ctrl_num,	po_ctrl_num,	vend_order_num,
		ticket_num,	date_received,	date_applied,
		date_aging,	date_doc,	date_required,
		date_discount,	class_code,	fob_code,
		terms_code)
SELECT	trx_ctrl_num,	po_ctrl_num,	vend_order_num,
		ticket_num,	date_received,	date_applied,
		date_aging,	date_doc,	date_required,
		date_discount,	class_code,	fob_code,
		terms_code
FROM	#apvahisx_work


DELETE #apvahisa_work
FROM aphisage a, #apvahisa_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num

INSERT	aphisage
		(trx_ctrl_num, 	date_aging)
SELECT	trx_ctrl_num, 	date_aging
FROM	#apvahisa_work







DELETE  apinpcdt
FROM	#apvacdt_work t, apinpcdt a
WHERE   t.trx_ctrl_num = a.trx_ctrl_num
AND   	t.trx_type = a.trx_type
AND     t.sequence_id = a.sequence_id
AND		(t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1






DELETE  apinpchg
FROM	#apvachg_work t, apinpchg a
WHERE   t.trx_ctrl_num = a.trx_ctrl_num
AND   	t.trx_type = a.trx_type
AND		(t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1





DELETE  apinpage
FROM	#apvaage_work t, apinpage a
WHERE   t.trx_ctrl_num = a.trx_ctrl_num
AND   	t.trx_type = a.trx_type
AND     t.sequence_id = a.sequence_id
AND		(t.db_action & 4) = 4

IF (@@error != 0)
	RETURN -1








EXEC @result = APVAUPSummary_sp  	@batch_ctrl_num, 
									@client_id,
									@user_id,
	                                @debug_level
IF(@result != 0 )
		RETURN @result








UPDATE apvohdr
SET	user_trx_type_code = b.user_trx_type_code,
	po_ctrl_num	= b.po_ctrl_num,	
	vend_order_num	= b.vend_order_num,
	ticket_num	= b.ticket_num,	
	date_received  = b.date_received,	
	date_required  = b.date_required,
	date_aging = b.date_aging,	
	date_doc	= b.date_doc,	
	date_discount	= b.date_discount,	
	date_due 	= b.date_due,
	fob_code	= b.fob_code,
	terms_code	= b.terms_code,
	state_flag	= 1,
	process_ctrl_num = ''
FROM apvohdr a, #apvaxv_work b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num



INSERT  apvahdr(
	trx_ctrl_num,		apply_to_num,	user_trx_type_code,
	batch_code,			po_ctrl_num,	vend_order_num,
	ticket_num,			date_posted,	date_applied,
	date_aging,			date_due,		date_doc,
	date_entered,		date_received,	date_required,
	date_discount,		fob_code,		terms_code,
	state_flag,			doc_desc,		user_id,
	journal_ctrl_num,	process_ctrl_num,	org_id
)
SELECT	trx_ctrl_num,       apply_to_num,           user_trx_type_code,     
		batch_code,			po_ctrl_num,            vend_order_num,         
		ticket_num,			@current_date,			date_applied,
		date_aging,         date_due,				date_doc,
		date_entered,       date_received,			date_required,
		date_discount,      fob_code,               terms_code,             
		1,			doc_desc,               user_id,
		gl_trx_id,			"",	org_id
FROM    #apvax_work
WHERE	(db_action & 2) = 2

IF (@@error != 0)
	RETURN -1





UPDATE	aptrxage
SET	date_aging = b.date_aging,
	date_due = b.date_due,
	date_doc = b.date_doc
FROM aptrxage a, #apvaxage_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.ref_id = b.ref_id













DECLARE @curr_comp varchar(8),
		@curr_db_name varchar(128)
SET @curr_comp = ''
WHILE 1 = 1
BEGIN
	SET ROWCOUNT 1
	SELECT @curr_comp = e.company_code, @curr_db_name = e.db_name 
	FROM #apvaxcdv_work b INNER JOIN ewcomp_vw e ON (e.company_code = b.rec_company_code)
	WHERE company_code > @curr_comp
	IF @@ROWCOUNT = 0
	begin
		SET ROWCOUNT 0 
		BREAK
	end
	SET ROWCOUNT 0 
	EXEC('UPDATE	apvodet
		SET	gl_exp_acct = b.gl_exp_acct,
			rec_company_code = b.rec_company_code,
			reference_code = b.reference_code,
			org_id = x.organization_id
		FROM apvodet a, #apvaxcdv_work b, ' + @curr_db_name + '..glchart x
		WHERE a.trx_ctrl_num = b.trx_ctrl_num
		AND a.sequence_id = b.sequence_id
		AND b.gl_exp_acct = x.account_code
		AND b.rec_company_code = ''' + @curr_comp + '''
		')	
END






SELECT @company_code = company_code FROM glco

IF EXISTS (SELECT installed 
		  FROM CVO_Control..sminst a, glcomp_vw b 
		  WHERE a.app_id = 18000 
		  AND installed = 1
		  AND a.company_id = b.company_id
		  AND b.company_code = @company_code
		   )
BEGIN

	CREATE TABLE #lc_apvoucher (trx_ctrl_num varchar(16))

	


	
	DELETE lc_apvoucher

	FROM 	#apvachg_work a, #apvacdt_work b, lc_glaccounts c, lc_apvoucher d
	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
	AND	a.apply_to_num = d.voucher_no
	AND 	b.rec_company_code = @company_code
	AND 	b.gl_exp_acct = c.account_code

	


	
	INSERT #lc_apvoucher (trx_ctrl_num)
	SELECT DISTINCT a.apply_to_num
	FROM 	#apvachg_work a, #apvacdt_work b, lc_glaccounts c
	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
	AND 	b.rec_company_code = @company_code
	AND 	b.new_gl_exp_acct = c.account_code

	


	DELETE	lc_apvoucher
	FROM	lc_apvoucher a, #lc_apvoucher b
	WHERE	a.voucher_no = b.trx_ctrl_num

	


	INSERT	lc_apvoucher (voucher_no)
	SELECT	trx_ctrl_num
	FROM	#lc_apvoucher

	DROP TABLE #lc_apvoucher

    	IF (@@error != 0)
	    	RETURN -1
END






INSERT  apvadet (
	trx_ctrl_num,			sequence_id,		gl_exp_acct,
	new_gl_exp_acct,		rec_company_code,	reference_code,
	new_rec_company_code,	new_reference_code,	org_id
)
SELECT	trx_ctrl_num,   		sequence_id,		gl_exp_acct,
    	new_gl_exp_acct,		rec_company_code, 	reference_code,
    	new_rec_company_code,	new_reference_code,	org_id
FROM    #apvaxcdt_work
WHERE	(db_action & 2) = 2

IF (@@error != 0)
	RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvamp.cpp" + ", line " + STR( 349, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAModifyPersistant_sp] TO [public]
GO
