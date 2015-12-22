SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROC [dbo].[CMMTValidate_sp]	@debug_level		smallint = 0
	
AS


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtv.cpp" + ", line " + STR( 45, 5 ) + " -- ENTRY: "
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtv.cpp" + ", line " + STR( 46, 5 ) + " -- MSG: " + "Load #cmmtvhdr"

INSERT #cmmtvhdr ( 
	trx_ctrl_num, 
	trx_type, 
	description, 
	batch_code, 
    	cash_acct_code,
	reference_code,
	user_id,
	date_applied,
	date_entered,
	hold_flag,
	posted_flag,
	total,
	currency_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	flag,
	org_id,
	interbranch_flag,
	temp_flag
)
SELECT 
	a.trx_ctrl_num,
	a.trx_type,
	"",
	a.batch_code,
    	a.cash_acct_code,
	a.reference_code,
	a.user_id,
	a.date_applied, 
	a.date_entered,
	0,
	0,
	a.total,
	b.nat_cur_code,
	a.rate_type_home,
	a.rate_type_oper,
	a.rate_home,
	a.rate_oper,
	0,
	a.org_id,
	a.interbranch_flag,
	a.temp_flag
FROM	#cmmanhdr_work a, apcash b
WHERE a.cash_acct_code = b.cash_acct_code

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtv.cpp" + ", line " + STR( 96, 5 ) + " -- MSG: " + "Load #cmmtvdtl"

INSERT #cmmtvdtl
(
	trx_ctrl_num,
	trx_type,
	sequence_id,
	doc_ctrl_num,
	date_document,
	trx_type_cls,
	account_code,
	reference_code,
	currency_code,
	amount_natural,
	amount_home,
	auto_rec_flag,
	flag,
	org_id,
	temp_flag
)
SELECT
	trx_ctrl_num,
	trx_type,
	sequence_id,
	doc_ctrl_num,
	date_document,
	trx_type_cls,
	account_code,
	reference_code,
	"",
	amount_natural,
	0.0,
	auto_rec_flag,
	0,
	org_id,
	temp_flag
FROM #cmmandtl_work


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtv.cpp" + ", line " + STR( 135, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMMTValidate_sp] TO [public]
GO
