SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[cmbidet1_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmbidet1.sp" + ", line " + STR( 25, 5 ) + " -- ENTRY: "



IF (SELECT err_type FROM cmedterr WHERE err_code = 30020) <= @error_level
BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmbidet1.sp" + ", line " + STR( 32, 5 ) + " -- MSG: " + "Document number not found in CM"

 INSERT #ewerror
	 SELECT 7000,
			 30020,
			 document_number,
			 "",
			 0,
			 0.0,
			 1,
			 document_number,
			 line,
			 "",
			 0
	 FROM #cmimport a
	 WHERE a.document_number NOT IN (SELECT doc_ctrl_num FROM cminpdtl 
	 								where cash_acct_code = a.cash_acct_code)
	 
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 30030) <= @error_level
BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmbidet1.sp" + ", line " + STR( 55, 5 ) + " -- MSG: " + "Document amount does not match the amount in CM"

 INSERT #ewerror
	 SELECT 7000,
			 30030,
			 document_number,
			 "",
			 0,
			 document_amount,
			 4,
			 document_number,
			 line,
			 "",
			 0
	 FROM #cmimport a, cminpdtl b
	 WHERE a.document_number = b.doc_ctrl_num
	 AND a.cash_acct_code = b.cash_acct_code
	 AND (ABS((a.document_amount)-(b.amount_book)) > 0.0000001)
	 
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 30040) <= @error_level
BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmbidet1.sp" + ", line " + STR( 79, 5 ) + " -- MSG: " + "Document has already been reconciled"

 INSERT #ewerror
	 SELECT 7000,
			 30040,
			 document_number,
			 "",
			 0,
			 0.0,
			 1,
			 document_number,
			 line,
			 "",
			 0
	 FROM #cmimport a, cminpdtl b
	 WHERE a.document_number = b.doc_ctrl_num
	 AND a.cash_acct_code = b.cash_acct_code
	 AND b.reconciled_flag = 1
	 AND b.closed_flag = 0
	 
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 30050) <= @error_level
BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmbidet1.sp" + ", line " + STR( 104, 5 ) + " -- MSG: " + "Document has already been reconciled and closed"

 INSERT #ewerror
	 SELECT 7000,
			 30050,
			 document_number,
			 "",
			 0,
			 0.0,
			 1,
			 document_number,
			 line,
			 "",
			 0
	 FROM #cmimport a, cminpdtl b
	 WHERE a.document_number = b.doc_ctrl_num
	 AND a.cash_acct_code = b.cash_acct_code
	 AND b.reconciled_flag = 1
	 AND b.closed_flag = 1
	 
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cmbidet1.sp" + ", line " + STR( 128, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cmbidet1_sp] TO [public]
GO
