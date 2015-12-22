SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[epvchdb_sp] 		
	@db_name varchar(30),
	@flag smallint,
	@only_errors smallint
AS
	DECLARE @error_level smallint


IF @only_errors = 1
	SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1

IF (SELECT err_type FROM epedterr WHERE err_code = 00160) <= @error_level
BEGIN
	
 INSERT #ewerror
	 SELECT 4000,
			 00160,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.control_num,
			 b.line,
			 "",
			 0
	 FROM #accounts b, glco c
 	 WHERE b.db_name = @db_name
 	 AND b.date_applied > c.period_end_date
END





IF (SELECT err_type FROM epedterr WHERE err_code = 00170) <= @error_level
BEGIN
	
 INSERT #ewerror
	 SELECT 4000,
			 00170,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.control_num,
			 b.line,
			 "",
			 0
	 FROM #accounts b, glprd c, glco d
 	 WHERE b.db_name = @db_name
 	 AND b.date_applied < c.period_start_date
	 AND c.period_end_date = d.period_end_date
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00180) <= @error_level
BEGIN
	
 UPDATE #accounts
 SET flag = 1
	 FROM #accounts, glprd c
 	 WHERE #accounts.db_name = @db_name
 	 AND #accounts.date_applied BETWEEN c.period_start_date AND c.period_end_date


 INSERT #ewerror
	 SELECT 4000,	
	 		 00180,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
 			 control_num,
			 line,
			 "",
			 0
	 FROM #accounts
 	 WHERE db_name = @db_name
 	 AND flag = 0



 UPDATE #accounts
 SET flag = 0
	 WHERE db_name = @db_name
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[epvchdb_sp] TO [public]
GO
