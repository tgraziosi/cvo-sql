SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

						



CREATE PROC [dbo].[CMMTModifyPermanent_sp]
											@batch_ctrl_num		varchar(16),
											@client_id 			varchar(20),
											@user_id			int,  
											@debug_level		smallint = 0
	
AS

DECLARE
	@errbuf				varchar(100),
	@result				int,
	@next_period        int,
	@date_applied       int,
	@company_code       varchar(8),
	@new_batch_code     varchar(16),
	@current_date       int,
	@home_cur_code varchar(8),
	@oper_cur_code varchar(8),
	@iv_flag		    smallint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtmp.cpp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "




EXEC appdate_sp @current_date OUTPUT		

SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num

SELECT @company_code = company_code FROM glco






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtmp.cpp" + ", line " + STR( 80, 5 ) + " -- MSG: " + "delete records in cmmandtl"
DELETE  cmmandtl
FROM	#cmmandtl_work a, cmmandtl b
WHERE   a.trx_ctrl_num = b.trx_ctrl_num
AND   	a.trx_type = b.trx_type
AND     a.sequence_id = b.sequence_id

IF (@@error != 0)
	RETURN -1





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtmp.cpp" + ", line " + STR( 94, 5 ) + " -- MSG: " + "delete records in cmmanhdr"
DELETE  cmmanhdr
FROM	#cmmanhdr_work a, cmmanhdr b
WHERE   a.trx_ctrl_num = b.trx_ctrl_num
AND   	a.trx_type = b.trx_type

IF (@@error != 0)
	RETURN -1





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtmp.cpp" + ", line " + STR( 107, 5 ) + " -- MSG: " + "insert cmtrxhdr"
INSERT  cmtrx(
	trx_ctrl_num,	trx_type,		batch_code,
	cash_acct_code,	reference_code,		user_id,		gl_trx_id,
	date_posted,	date_applied,	date_entered,	org_id 
	)
SELECT	trx_ctrl_num,	trx_type,		batch_code,
	cash_acct_code,	reference_code, user_id,		gl_trx_id,
	date_posted,	date_applied,	date_entered,	org_id 
FROM    #cmtrx_work

IF (@@error != 0)
	RETURN -1





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtmp.cpp" + ", line " + STR( 125, 5 ) + " -- MSG: " + "insert cmtrxdtl"
INSERT  cmtrxdtl (
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	date_document,
	trx_type_cls,
	account_code,
	reference_code,
	currency_code,
	amount_natural,
	amount_home,
	auto_rec_flag,
	sequence_id,
	org_id
)
SELECT	
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	date_document,
	trx_type_cls,
	account_code,
	reference_code,
	'',	
	amount_natural,
	0.0,
	auto_rec_flag,
	sequence_id,
	org_id
FROM    #cmtrxdtl_work

IF (@@error != 0)
	RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtmp.cpp" + ", line " + STR( 162, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMMTModifyPermanent_sp] TO [public]
GO
