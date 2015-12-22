SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cmindet1_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmindet1.sp" + ", line " + STR( 24, 5 ) + " -- ENTRY: "


IF (SELECT err_type FROM cmedterr WHERE err_code = 20010) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmindet1.sp" + ", line " + STR( 29, 5 ) + " -- MSG: " + "Check if document already exists"

 INSERT #ewerror
	 SELECT 7000,
			 20010,
			 a.doc_ctrl_num,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #cminvdtl a, cminpdtl b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND	a.doc_ctrl_num = b.doc_ctrl_num
 AND	a.cash_acct_code = b.cash_acct_code
	 AND	a.trx_type = b.trx_type
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 20020) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmindet1.sp" + ", line " + STR( 52, 5 ) + " -- MSG: " + "Cash account is not valid"

 INSERT #ewerror
	 SELECT 7000,
			 20020,
			 cash_acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #cminvdtl
	 WHERE cash_acct_code NOT IN (SELECT cash_acct_code FROM apcash)
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 20030) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmindet1.sp" + ", line " + STR( 72, 5 ) + " -- MSG: " + "Transaction to void not found"

	 UPDATE #cminvdtl
	 SET flag = 1
	 FROM #cminvdtl, cminpdtl b
	 WHERE #cminvdtl.void_flag = 1
	 AND	b.trx_ctrl_num = #cminvdtl.apply_to_trx_num
 AND	b.doc_ctrl_num = #cminvdtl.apply_to_doc_num
	 AND	b.cash_acct_code = #cminvdtl.cash_acct_code
	 AND	b.trx_type = #cminvdtl.apply_to_trx_type


 INSERT #ewerror
	 SELECT 7000,
			 20030,
			 apply_to_doc_num,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #cminvdtl
	 WHERE void_flag = 1
	 AND flag != 1

	 UPDATE #cminvdtl
	 SET flag = 0
	 WHERE flag = 1
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 20040) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmindet1.sp" + ", line " + STR( 108, 5 ) + " -- MSG: " + "Transaction to void already closedd"


 INSERT #ewerror
	 SELECT 7000,
			 20040,
			 a.apply_to_doc_num,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #cminvdtl a, cminpdtl b
	 WHERE a.void_flag = 1
	 AND	b.trx_ctrl_num = a.apply_to_trx_num
 AND	b.doc_ctrl_num = a.apply_to_doc_num
	 AND	b.cash_acct_code = a.cash_acct_code
	 AND	b.trx_type = a.apply_to_trx_type
	 AND	b.closed_flag = 1

END

IF (SELECT err_type FROM cmedterr WHERE err_code = 20050) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmindet1.sp" + ", line " + STR( 135, 5 ) + " -- MSG: " + "Transaction to void already voided"


 INSERT #ewerror
	 SELECT 7000,
			 20050,
			 a.apply_to_doc_num,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #cminvdtl a, cminpdtl b
	 WHERE a.void_flag = 1
	 AND	b.trx_ctrl_num = a.apply_to_trx_num
 AND	b.doc_ctrl_num = a.apply_to_doc_num
	 AND	b.cash_acct_code = a.cash_acct_code
	 AND	b.trx_type = a.apply_to_trx_type
	 AND	b.void_flag = 1

END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmindet1.sp" + ", line " + STR( 164, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cmindet1_sp] TO [public]
GO
