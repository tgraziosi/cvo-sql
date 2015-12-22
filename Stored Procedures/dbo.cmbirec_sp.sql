SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cmbirec_sp] @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbirec.cpp" + ", line " + STR( 24, 5 ) + " -- ENTRY: "

UPDATE cminpdtl
SET reconciled_flag = 1,
    date_cleared = b.date_cleared
FROM cminpdtl, #cmimport b,apcash a  
WHERE  (cminpdtl.doc_ctrl_num = b.document_number
  OR SUBSTRING(cminpdtl.doc_ctrl_num,a.check_start_col,a.check_length) = b.document_number) 
AND cminpdtl.cash_acct_code = b.cash_acct_code
AND b.cash_acct_code = a.cash_acct_code  
AND (ABS((ABS(cminpdtl.amount_book))-(ABS(b.document_amount))) < 0.0000001)
AND reconciled_flag = 0


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbirec.cpp" + ", line " + STR( 38, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cmbirec_sp] TO [public]
GO
