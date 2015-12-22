SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvadb_sp] @db_name varchar(30),
						 @header_db varchar(30),
						 @flag smallint,
						 @only_errors smallint,
						 @debug_level smallint = 0
AS
	DECLARE @error_level smallint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 30, 5 ) + " -- ENTRY: "

IF @only_errors = 1
 SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1


 

 IF (@flag = 1)
 BEGIN
	IF (SELECT err_type FROM apedterr WHERE err_code = 30827) <= @error_level
	 BEGIN

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 48, 5 ) + " -- MSG: " + "Unable to switch to database"
 INSERT #ewerror
	 SELECT 4000,
			 30827,
			 a.db_name,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	 FROM #apveacct a
	 WHERE a.db_name = @db_name
	 END
	 RETURN 0
	END



IF (SELECT err_type FROM apedterr WHERE err_code = 31040) <= @error_level
 BEGIN


 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 73, 5 ) + " -- MSG: " + "validate accounts exist in glchart"
 INSERT #ewerror
	 SELECT 4000,
			 31040,
			 a.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	 FROM #apveacct a
	 WHERE a.db_name = @db_name
	 AND a.type = 1
	 AND a.acct_code NOT IN (SELECT account_code FROM glchart)
END

IF (SELECT err_type FROM apedterr WHERE err_code = 31051) <= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 94, 5 ) + " -- MSG: " + "check if account is inactive"
 INSERT #ewerror
	 SELECT 4000,
			 31051,
			 a.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	 FROM #apveacct a, glchart b
	 WHERE a.db_name = @db_name
	 AND a.type = 1
	 AND a.acct_code = b.account_code
	 AND b.inactive_flag = 1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 31052) <= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 117, 5 ) + " -- MSG: " + "check if account is invalid for the apply date"
 INSERT #ewerror
	 SELECT 4000,
			 31052,
			 a.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	 FROM #apveacct a, glchart b
	 WHERE a.db_name = @db_name
	 AND a.type = 1
	 AND a.acct_code = b.account_code
	 AND ((a.date_applied < b.active_date
	 AND b.active_date != 0)
	 OR (a.date_applied > b.inactive_date
	 AND b.inactive_date != 0))
END

 


IF (SELECT err_type FROM apedterr WHERE err_code = 31059) <= @error_level
 BEGIN

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 146, 5 ) + " -- MSG: " + "Check if reference code exists or is blank"
 INSERT #ewerror
	 SELECT 4000,
			 31059,
			 b.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.vchr_num,
			 b.line,
			 "",
			 0
	 FROM #apveacct b 
 	 WHERE b.db_name = @db_name
	 AND b.reference_code NOT IN (SELECT reference_code FROM glref) 
	 AND b.reference_code != ""
END


IF (SELECT err_type FROM apedterr WHERE err_code = 31056) <= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 168, 5 ) + " -- MSG: " + "Check if reference code is required"
 UPDATE #apveacct
	 SET flag = 1
	 FROM #apveacct, glrefact b
	 WHERE #apveacct.db_name = @db_name
	 AND #apveacct.acct_code LIKE b.account_mask
	 AND b.reference_flag = 1
	 AND #apveacct.reference_code = ""


 INSERT #ewerror
	 SELECT 4000,
			 31056,
			 a.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	 FROM #apveacct a, glrefact b
 	 WHERE a.db_name = @db_name
	 AND a.acct_code LIKE b.account_mask
	 AND b.reference_flag = 3
	 AND a.reference_code = ""
	 AND a.flag = 0

	 UPDATE #apveacct
	 SET flag = 0
	 WHERE flag <> 0
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 204, 5 ) + " -- MSG: " + "Check if reference code is excluded invalid"
	 

 UPDATE #apveacct
	 SET flag = 1
	 FROM #apveacct, glref b, glrefact c, glratyp d
	 WHERE #apveacct.db_name = @db_name
	 AND #apveacct.acct_code LIKE c.account_mask
	 AND #apveacct.reference_code = b.reference_code
	 AND c.account_mask = d.account_mask
	 AND c.reference_flag = 1
	 AND d.reference_type = b.reference_type
	 AND #apveacct.reference_code != ""


IF (SELECT err_type FROM apedterr WHERE err_code = 31058) <= @error_level
 BEGIN
	 
 INSERT #ewerror
	 SELECT 4000,
			 31058,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	 FROM #apveacct a
 	 WHERE a.db_name = @db_name
	 AND a.flag = 1
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 245, 5 ) + " -- MSG: " + "Check if reference code is not allowed"
	 
 UPDATE #apveacct
	 SET flag = 2
	 FROM #apveacct, glrefact b
	 WHERE #apveacct.db_name = @db_name
	 AND #apveacct.acct_code LIKE b.account_mask
	 AND #apveacct.reference_code != ""
	 AND b.reference_flag IN (2,3)
	 AND #apveacct.flag = 0


IF (SELECT err_type FROM apedterr WHERE err_code = 31057) <= @error_level
 BEGIN
	 
 INSERT #ewerror
	 SELECT 4000,
			 31057,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	 FROM #apveacct a
 	 WHERE a.db_name = @db_name
	 AND a.flag = 0
	 AND a.reference_code != ""
END


	 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 287, 5 ) + " -- MSG: " + "Check if reference code is required or optional and invalid"
	 
 UPDATE #apveacct
	 SET flag = 3
	 FROM #apveacct, glref b, glrefact c, glratyp d
	 WHERE #apveacct.db_name = @db_name
	 AND #apveacct.acct_code LIKE c.account_mask
	 AND #apveacct.reference_code = b.reference_code
	 AND c.account_mask = d.account_mask
	 AND c.reference_flag IN (2,3)
	 AND d.reference_type = b.reference_type
	 AND #apveacct.reference_code != ""
	 AND #apveacct.flag = 2

IF (SELECT err_type FROM apedterr WHERE err_code = 31058) <= @error_level
 BEGIN
	 
 INSERT #ewerror
	 SELECT 4000,
			 31058,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	 FROM #apveacct a
 	 WHERE a.db_name = @db_name
	 AND a.flag = 2
END



IF @db_name != @header_db
 BEGIN


IF (SELECT err_type FROM apedterr WHERE err_code = 30975) <= @error_level
 BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 334, 5 ) + " -- MSG: " + "Check if applied to future period"
	
 INSERT #ewerror
	 SELECT 4000,
			 30975,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.vchr_num,
			 b.line,
			 "",
			 0
	 FROM #apveacct b, glco c
 	 WHERE b.db_name = @db_name
 	 AND b.date_applied > c.period_end_date
END






IF (SELECT err_type FROM apedterr WHERE err_code = 30976) <= @error_level
 BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 363, 5 ) + " -- MSG: " + "Check if applied to prior period"
	
 INSERT #ewerror
	 SELECT 4000,
			 30976,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.vchr_num,
			 b.line,
			 "",
			 0
	 FROM #apveacct b, glprd c, glco d
 	 WHERE b.db_name = @db_name
 	 AND b.date_applied < c.period_start_date
	 AND c.period_end_date = d.period_end_date
END

IF (SELECT err_type FROM apedterr WHERE err_code = 30977) <= @error_level
 BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 388, 5 ) + " -- MSG: " + "Check if applied period exists"
	
 UPDATE #apveacct
 SET flag = 1
	 FROM #apveacct, glprd c
 	 WHERE #apveacct.db_name = @db_name
 	 AND #apveacct.date_applied BETWEEN c.period_start_date AND c.period_end_date


 INSERT #ewerror
	 SELECT 4000,	
	 		 30977,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
 			 vchr_num,
			 line,
			 "",
			 0
	 FROM #apveacct
 	 WHERE db_name = @db_name
 	 AND flag = 0



 UPDATE #apveacct
 SET flag = 0
	 WHERE db_name = @db_name
END

END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvadb.sp" + ", line " + STR( 425, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvadb_sp] TO [public]
GO
