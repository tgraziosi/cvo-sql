SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APVAUpdatePostedRecords_sp] @debug_level smallint = 0
AS


							 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvaupr.sp" + ", line " + STR( 49, 5 ) + " -- ENTRY: "

UPDATE #apvaxcdv_work
SET rec_company_code = b.new_rec_company_code,
	gl_exp_acct = b.new_gl_exp_acct,
	reference_code = b.new_reference_code,
	db_action = 1
FROM #apvaxcdv_work a, #apvacdt_work b, #apvachg_work c
WHERE a.trx_ctrl_num = c.apply_to_num
AND b.trx_ctrl_num = c.trx_ctrl_num
AND a.sequence_id = b.sequence_id

IF (@@error != 0)
	RETURN -1

UPDATE	#apvaxv_work
SET	user_trx_type_code = b.user_trx_type_code,
	po_ctrl_num	= b.po_ctrl_num,	
	vend_order_num	= b.vend_order_num,
	ticket_num	= b.ticket_num,	
	date_received = b.date_received,	
	date_required = b.date_required,
	date_aging = b.date_aging,	
	date_doc	= b.date_doc,	
	date_discount	= b.date_discount,	
	date_due 	= b.date_due,
	fob_code	= b.fob_code,
	terms_code	= b.terms_code,
	db_action	= a.db_action|1
FROM #apvaxv_work a, #apvachg_work b
WHERE	a.trx_ctrl_num = b.apply_to_num

IF (@@error != 0)
	RETURN -1



UPDATE	#apvaxage_work
SET	date_aging = b.date_aging,
	date_due = b.date_due,
	date_doc = c.date_doc,
	db_action = a.db_action|1
FROM #apvaxage_work a, #apvaage_work b, #apvachg_work c
WHERE	a.trx_ctrl_num = c.apply_to_num
AND b.trx_ctrl_num = c.trx_ctrl_num
AND a.ref_id = b.sequence_id
AND a.trx_type = 4091

IF (@@error != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvaupr.sp" + ", line " + STR( 101, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAUpdatePostedRecords_sp] TO [public]
GO
