SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[eprecdb_sp] 	@db_name varchar(30),
			 @flag smallint,
			 @only_errors smallint
AS
	DECLARE @error_level smallint


IF @only_errors = 1
	SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1


IF (SELECT err_type FROM epedterr WHERE err_code = 10040) <= @error_level
BEGIN
	
	INSERT #ewerror
	SELECT 4000,
			 10040,
			 a.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.control_num,
			 a.line,
			 "",
			 0
	FROM #accounts a
	WHERE a.db_name = @db_name
	AND a.type = 1
	AND a.acct_code NOT IN (SELECT account_code FROM glchart)
END


IF (SELECT err_type FROM epedterr WHERE err_code = 10050) <= @error_level
BEGIN
	
	INSERT #ewerror
	SELECT 4000,
			 10050,
			 a.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.control_num,
			 a.line,
			 "",
			 0
	 FROM #accounts a, glchart b
	 WHERE a.db_name = @db_name
	 AND a.type = 1
	 AND a.acct_code = b.account_code
	 AND b.inactive_flag = 1
END



IF (SELECT err_type FROM epedterr WHERE err_code = 10110) <= @error_level
BEGIN

	
	INSERT #ewerror
	SELECT 4000,
			 10110,
			 b.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.control_num,
			 b.line,
			 "",
			 0
	FROM #accounts b 
 	WHERE b.db_name = @db_name
	AND b.reference_code NOT IN (SELECT reference_code FROM glref) 
	AND b.reference_code != ""
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10070) <= @error_level
BEGIN

	
	UPDATE #accounts
	SET flag = 1
	FROM #accounts, glrefact b
	WHERE #accounts.db_name = @db_name
	AND #accounts.acct_code LIKE b.account_mask
	AND b.reference_flag = 1
	AND #accounts.reference_code = ""


	INSERT #ewerror
	SELECT 4000,
			 10070,
			 a.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.control_num,
			 a.line,
			 "",
			 0
	FROM #accounts a, glrefact b
 	WHERE a.db_name = @db_name
	AND a.acct_code LIKE b.account_mask
	AND b.reference_flag = 3
	AND a.reference_code = ""
	AND a.flag = 0

	UPDATE #accounts
	SET flag = 0
	WHERE flag <> 0
END



	

	UPDATE #accounts
	 SET flag = 1
	 FROM #accounts, glref b, glrefact c, glratyp d
	 WHERE #accounts.db_name = @db_name
	 AND #accounts.acct_code LIKE c.account_mask
	 AND #accounts.reference_code = b.reference_code
	 AND c.account_mask = d.account_mask
	 AND c.reference_flag = 1
	 AND d.reference_type = b.reference_type
	 AND #accounts.reference_code != ""

IF (SELECT err_type FROM epedterr WHERE err_code = 10090) <= @error_level
BEGIN
	 
	INSERT #ewerror
	SELECT 4000,
			 10090,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.control_num,
			 a.line,
			 "",
			 0
	FROM #accounts a
 	WHERE a.db_name = @db_name
	AND a.flag = 1
END



	
	UPDATE #accounts
	 SET flag = 2
	 FROM #accounts, glrefact b
	 WHERE #accounts.db_name = @db_name
	 AND #accounts.acct_code LIKE b.account_mask
	 AND #accounts.reference_code != ""
	 AND b.reference_flag IN (2,3)
	 AND #accounts.flag = 0

IF (SELECT err_type FROM epedterr WHERE err_code = 10090) <= @error_level
BEGIN
	 
	INSERT #ewerror
	SELECT 4000,
			 10090,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.control_num,
			 a.line,
			 "",
			 0
	FROM #accounts a
 	WHERE a.db_name = @db_name
	AND a.flag = 0
	AND a.reference_code != ""
END


	 

	
	UPDATE #accounts
	 SET flag = 3
	 FROM #accounts, glref b, glrefact c, glratyp d
	 WHERE #accounts.db_name = @db_name
	 AND #accounts.acct_code LIKE c.account_mask
	 AND #accounts.reference_code = b.reference_code
	 AND c.account_mask = d.account_mask
	 AND c.reference_flag IN (2,3)
	 AND d.reference_type = b.reference_type
	 AND #accounts.reference_code != ""
	 AND #accounts.flag = 2

IF (SELECT err_type FROM epedterr WHERE err_code = 10100) <= @error_level
BEGIN
	 
	INSERT #ewerror
	 SELECT 4000,
			 10100,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.control_num,
			 a.line,
			 "",
			 0
	 FROM #accounts a
 	 WHERE a.db_name = @db_name
	 AND a.flag = 2
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[eprecdb_sp] TO [public]
GO
