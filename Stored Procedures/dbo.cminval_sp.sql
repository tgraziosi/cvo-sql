SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE PROCEDURE        [dbo].[cminval_sp] @debug_level smallint = 0
			
AS

DECLARE @result int                

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cminval.cpp" + ", line " + STR( 29, 5 ) + " -- ENTRY: "

IF (SELECT COUNT(*) FROM #cminpdtl) = 0
   RETURN -2

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cminval.cpp" + ", line " + STR( 34, 5 ) + " -- MSG: " + "Load #cminvdtl"

INSERT #cminvdtl (
	rec_id,
	trx_type,
	trx_ctrl_num,
	doc_ctrl_num,
	date_document,
	description,
	document1,
	document2,
	cash_acct_code,
	amount_book,
	reconciled_flag,
	closed_flag,
	void_flag,
	date_applied,
	cleared_type,
	apply_to_trx_num,
	apply_to_trx_type,
	apply_to_doc_num,
	flag,
	org_id)
SELECT 
 	0,
	trx_type,
	trx_ctrl_num,
	doc_ctrl_num,
	date_document,
	description,
	document1,
	document2,
	cash_acct_code,
	amount_book,
	reconciled_flag,
	closed_flag,
	void_flag,
	date_applied,
	cleared_type,
	ISNULL(apply_to_trx_num,""),
	ISNULL(apply_to_trx_type,0),
	ISNULL(apply_to_doc_num,""),
	0,
	org_id 
FROM	#cminpdtl


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cminval.cpp" + ", line " + STR( 81, 5 ) + " -- EXIT: "
			




RETURN 0

GO
GRANT EXECUTE ON  [dbo].[cminval_sp] TO [public]
GO
