SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE 	[dbo].[appadet1_sp]	@error_level smallint, 
								@debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appadet1.cpp" + ", line " + STR( 29, 5 ) + " -- ENTRY: "
  DECLARE @ib_flag		INTEGER




SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco




IF @ib_flag = 1 
BEGIN
	



	IF (SELECT err_type FROM apedterr WHERE err_code = 40890) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appadet1.cpp" + ", line " + STR( 53, 5 ) + " -- MSG: " + "Validate organization exists and is active in Detail"
		


		

































		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	40890, 		org_id,
			org_id, 		0, 		0.0,
			1, 			trx_ctrl_num, 	sequence_id,
			"", 			0
		FROM 	#appavpdt a
			LEFT JOIN Organization o ON a.org_id = o.organization_id and o.active_flag = 1
		WHERE o.organization_id IS NULL


  	END
	
END
ELSE
BEGIN
	


	IF (SELECT err_type FROM apedterr WHERE err_code = 40900) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same apinpchg/apinpcdt"

		




































		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 			40900, 			b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 		0.0,
			0, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#appavpdt a
				INNER JOIN #appavpyt b ON a.trx_ctrl_num = b.trx_ctrl_num
				LEFT JOIN #appavpyt c ON a.trx_ctrl_num = c.trx_ctrl_num AND a.trx_type = c.trx_type AND a.org_id = c.org_id
		WHERE c.org_id IS NULL



	END
END



IF (SELECT err_type FROM apedterr WHERE err_code = 40550) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appadet1.cpp" + ", line " + STR( 182, 5 ) + " -- MSG: " + "Check if sequence_id <= 0"
	


	  INSERT #ewerror
	  SELECT 4000,
			 40550,
			 "",
			 "",
			 sequence_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #appavpdt 
	  WHERE sequence_id <= 0
END

IF (SELECT err_type FROM apedterr WHERE err_code = 40560) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appadet1.cpp" + ", line " + STR( 204, 5 ) + " -- MSG: " + "Check if apply_to_num exists in aptrx"
	


	  INSERT #ewerror
	  SELECT 4000,
			 40560,
			 apply_to_num,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #appavpdt 
	  WHERE apply_to_num NOT IN (SELECT trx_ctrl_num FROM apvohdr)
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appadet1.cpp" + ", line " + STR( 226, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appadet1_sp] TO [public]
GO
