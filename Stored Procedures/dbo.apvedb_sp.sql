SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvedb_sp] @db_name varchar(30),
						   @header_db varchar(30),
						   @flag smallint,
						   @only_errors smallint,
						   @debug_level smallint = 0
AS
	DECLARE @error_level smallint
	
	DECLARE	@org_id varchar(30), @ib_flag  int, @ib_segment int, @ib_offset int,@ib_length int, 
			@where_added varchar(600)
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 46, 5 ) + " -- ENTRY: "

IF @only_errors = 1
   SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1


 




 IF (@flag = 1)
    BEGIN
	IF (SELECT err_type FROM apedterr WHERE err_code = 10827) <= @error_level
	  BEGIN

      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 64, 5 ) + " -- MSG: " + "Unable to switch to database"
      INSERT #ewerror
	  SELECT 4000,
			 10827,
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

	  RETURN 0

	  END	
	END





IF (SELECT err_type FROM apedterr WHERE err_code = 11040) <= @error_level
BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 91, 5 ) + " -- MSG: " + "validate accounts exist in glchart"
      INSERT #ewerror
	  SELECT 4000,
			 11040,
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
		LEFT JOIN glchart CHRT ON a.acct_code = CHRT.account_code
	  WHERE a.db_name = @db_name
	  AND a.type = 1
	  AND CHRT.account_code IS NULL
	  
END


IF (SELECT err_type FROM apedterr WHERE err_code = 11051) <= @error_level
BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 115, 5 ) + " -- MSG: " + "check if account is inactive"
      INSERT #ewerror
	  SELECT 4000,
			 11051,
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
		INNER JOIN glchart b ON a.acct_code = b.account_code AND b.inactive_flag = 1
	  WHERE a.db_name = @db_name
	  AND a.type = 1
END

IF (SELECT err_type FROM apedterr WHERE err_code = 11052) <= @error_level
BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 136, 5 ) + " -- MSG: " + "check if account is invalid for the apply date"
      INSERT #ewerror
	  SELECT 4000,
			 11052,
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

 


IF (SELECT err_type FROM apedterr WHERE err_code = 11059) <= @error_level
BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 165, 5 ) + " -- MSG: " + "Check if reference code exists or is blank"
      INSERT #ewerror
	  SELECT 4000,
			 11059,
			 b.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.vchr_num,
			 b.line,
			 "",
			 0
	  FROM  #apveacct b 
		LEFT JOIN glref REF ON b.reference_code = REF.reference_code 
  	  WHERE  b.db_name = @db_name
	  AND b.reference_code != ""
	  AND REF.reference_code IS NULL
END

IF (SELECT err_type FROM apedterr WHERE err_code = 11056) <= @error_level
BEGIN

  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 188, 5 ) + " -- MSG: " + "Check if reference code is required"

      INSERT #ewerror
	  SELECT 4000,
			 11056,
			 a.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	  FROM  #apveacct a
		INNER JOIN glrefact b ON a.acct_code LIKE b.account_mask AND b.reference_flag = 3
		LEFT JOIN (SELECT acct_code
					FROM #apveacct
						INNER JOIN glrefact b ON #apveacct.acct_code LIKE b.account_mask AND b.reference_flag = 1
					WHERE #apveacct.db_name = @db_name 
					AND #apveacct.reference_code = "") TEMP ON a.acct_code = TEMP.acct_code
  	  WHERE  a.db_name = @db_name
	  AND a.reference_code = ""
	  AND TEMP.acct_code IS NULL
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 216, 5 ) + " -- MSG: " + "Check if reference code is excluded invalid"
	  



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

IF (SELECT err_type FROM apedterr WHERE err_code = 11058) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 4000,
			 11058,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	  FROM  #apveacct a
  	  WHERE  a.db_name = @db_name
	  AND a.flag = 1
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 256, 5 ) + " -- MSG: " + "Check if reference code is not allowed"
	  


      UPDATE #apveacct
	  SET flag = 2
	  FROM #apveacct, glrefact b
	  WHERE #apveacct.db_name = @db_name
	  AND #apveacct.acct_code LIKE b.account_mask
	  AND #apveacct.reference_code != ""
	  AND b.reference_flag IN (2,3)
	  AND #apveacct.flag = 0

IF (SELECT err_type FROM apedterr WHERE err_code = 11057) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 4000,
			 11057,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	  FROM  #apveacct a
  	  WHERE  a.db_name = @db_name
	  AND a.flag = 0
	  AND a.reference_code != ""
END


	 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 297, 5 ) + " -- MSG: " + "Check if reference code is required or optional and invalid"
	  


      UPDATE #apveacct
	  SET flag = 3
	  FROM #apveacct
		INNER JOIN glref b ON #apveacct.reference_code = b.reference_code
		INNER JOIN glrefact c ON #apveacct.acct_code LIKE c.account_mask 
		INNER JOIN glratyp d ON d.reference_type = b.reference_type AND d.account_mask = c.account_mask
	  WHERE #apveacct.db_name = @db_name
	  AND c.reference_flag IN (2,3)
	  AND #apveacct.reference_code != ""
	  AND #apveacct.flag = 2

IF (SELECT err_type FROM apedterr WHERE err_code = 11058) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 4000,
			 11058,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.vchr_num,
			 a.line,
			 "",
			 0
	  FROM  #apveacct a
  	  WHERE  a.db_name = @db_name
	  AND a.flag = 2
END



IF (SELECT err_type FROM apedterr WHERE err_code = 19190) <= @error_level
BEGIN		
	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 341, 5 ) + " -- MSG: " + "Validate organization exists and is active in Detail"
	  INSERT #ewerror
	  SELECT 4000,	
	  		 19190,
			 a.org_id,
			 "",
			 0,
			 0.0,
			 3,
  			 a.vchr_num,
			 a.line,
			 "",
			 0
	  FROM #apveacct a
		LEFT JOIN Organization o ON a.org_id = o.organization_id AND o.active_flag = 1
  	  WHERE db_name = @db_name
  	  AND o.organization_id IS NULL


END
IF (SELECT err_type FROM apedterr WHERE err_code = 19200) <= @error_level
BEGIN

	



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \apinpcdt"

	UPDATE 	#apveacct
	SET 	flag = 0
	FROM 	#apveacct a
	WHERE	 a.db_name = @db_name

	
	SELECT 	@ib_flag  = ib_flag, @ib_offset = ib_offset,	@ib_length = ib_length,	@ib_segment = ib_segment
	FROM	glco

	IF @ib_flag = 1
		SELECT @where_added = 'o.branch_account_number = SUBSTRING(seg'+cast(@ib_segment as varchar(2)) +'_code,'+ cast(@ib_offset as varchar(2))+','+cast(@ib_length as varchar(2))+')'
	ELSE
	BEGIN
		SELECT 	@org_id = organization_id
		FROM	Organization_all			
		WHERE	outline_num = '1'	

		SELECT @where_added = 'o.organization_id = ''' + @org_id + ''''
	END


	EXEC('UPDATE #apveacct SET flag = 1 FROM #apveacct a , glchart c, Organization_all o '+
	' WHERE a.acct_code = c.account_code ' +
	' AND ' + @where_added +
	' AND a.org_id = o.organization_id')
		

  	INSERT #ewerror
	  SELECT 4000,	
	  		 19200,
			 acct_code,
			 org_id,
			 0,
			 0.0,
			 3,
  			 vchr_num,
			 line,
			 "",
			 0
	  FROM #apveacct
  	  WHERE db_name = @db_name
  	  AND flag = 0
END



IF @db_name != @header_db
   BEGIN


IF (SELECT err_type FROM apedterr WHERE err_code = 10975) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 422, 5 ) + " -- MSG: " + "Check if applied to future period"
	


      INSERT #ewerror
	  SELECT 4000,
			 10975,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.vchr_num,
			 b.line,
			 "",
			 0
	  FROM  #apveacct b
		INNER JOIN glco c ON b.date_applied > c.period_end_date
  	  WHERE  b.db_name = @db_name
END





IF (SELECT err_type FROM apedterr WHERE err_code = 10976) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 449, 5 ) + " -- MSG: " + "Check if applied to prior period"
	


      INSERT #ewerror
	  SELECT 4000,
			 10976,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.vchr_num,
			 b.line,
			 "",
			 0
	  FROM #apveacct b
		INNER JOIN glprd c ON b.date_applied < c.period_start_date
		INNER JOIN glco d ON c.period_end_date = d.period_end_date
  	  WHERE b.db_name = @db_name
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10977) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 473, 5 ) + " -- MSG: " + "Check if applied period exists"
	


      INSERT #ewerror
	  SELECT 4000,	
	  		 10977,
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
		LEFT OUTER JOIN glprd c ON #apveacct.date_applied BETWEEN c.period_start_date AND c.period_end_date
  	  WHERE #apveacct.db_name = @db_name
		AND c.period_start_date IS NULL

END



END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedb.cpp" + ", line " + STR( 501, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvedb_sp] TO [public]
GO
