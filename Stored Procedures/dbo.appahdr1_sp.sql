SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[appahdr1_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 26, 5 ) + " -- ENTRY: "

DECLARE @ib_flag		INTEGER




SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco




UPDATE  #appavpyt
SET     interbranch_flag = 1
FROM 	#appavpyt a, #appavpdt b 
WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
AND   	a.org_id <> b.org_id





IF @ib_flag = 1 
BEGIN
	

















































	
	




	IF (SELECT err_type FROM apedterr WHERE err_code = 40860) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 110, 5 ) + " -- MSG: " + "Validate a relationship exists for all organizations in an inter-organization trx in apinpchg/apinpcdt"

		







































		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	40860, 			a.org_id + ' - ' + b.org_id,
			a.org_id, 		user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	b.sequence_id,
			'', 			0
		FROM 	#appavpyt a
			INNER JOIN #appavpdt b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.org_id <> b.org_id
			LEFT JOIN (	SELECT a.trx_ctrl_num 
						FROM 	#appavpyt a
						INNER JOIN #appavpdt b ON a.trx_ctrl_num = b.trx_ctrl_num
						INNER JOIN OrganizationOrganizationRel oor ON a.org_id = oor.controlling_org_id	AND b.org_id = oor.detail_org_id) TEMP ON a.trx_ctrl_num = TEMP.trx_ctrl_num 
		WHERE 	a.interbranch_flag = 1
		AND TEMP.trx_ctrl_num IS NULL


	END


	



	IF (SELECT err_type FROM apedterr WHERE err_code = 40880) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 184, 5 ) + " -- MSG: " + "Validate organization exists and is active in Header"
		
























		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	40880, 		org_id,
			org_id, 		user_id, 	0.0,
			1, 			trx_ctrl_num, 	0,
			"", 			0
		FROM 	#appavpyt a
			LEFT JOIN Organization ood ON a.org_id = ood.organization_id AND ood.active_flag = 1
		WHERE ood.organization_id IS NULL

		

	END

END


	
IF (SELECT err_type FROM apedterr WHERE err_code = 40010) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 234, 5 ) + " -- MSG: " + "Validate trxctrlnum doesn't exist in appahdr"
	


      INSERT #ewerror
	  SELECT 4000,
			 40010,
			 a.trx_ctrl_num,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt a, appahdr b
  	  WHERE a.trx_ctrl_num = b.trx_ctrl_num
END





IF (SELECT err_type FROM apedterr WHERE err_code = 40080) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 260, 5 ) + " -- MSG: " + "Check cash_acct_code is blank"
	


      INSERT #ewerror
	  SELECT 4000,
			 40080,
			 cash_acct_code,
			 "",
			 0,
			 0.0,
			 1,
	    	 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt 
	  WHERE cash_acct_code = ""
	  AND payment_type = 1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 40090) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 284, 5 ) + " -- MSG: " + "Check cash_acct_code exists in apcash"
	





















      INSERT #ewerror
	  SELECT 4000,
			 40090,
			 a.cash_acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt a
		LEFT JOIN apcash b ON a.cash_acct_code = b.cash_acct_code
  	  WHERE a.payment_type = 1
	  AND a.cash_acct_code != ""
	  AND b.cash_acct_code IS NULL

END


IF (SELECT err_type FROM apedterr WHERE err_code = 40100) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 330, 5 ) + " -- MSG: " + "Check cash_acct_code exists in glchart"
	


      

















	INSERT #ewerror
	  SELECT 4000,
			 40100,
			 a.cash_acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt a
		LEFT JOIN glchart c ON a.cash_acct_code = c.account_code
  	  WHERE a.payment_type = 1
	  AND a.cash_acct_code != ""
	  AND c.account_code IS NULL

END


IF (SELECT err_type FROM apedterr WHERE err_code = 40111) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 375, 5 ) + " -- MSG: " + "check if cash account is inactive"
      INSERT #ewerror
	  SELECT 4000,
			 40111,
			 b.cash_acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt b, glchart c
	  WHERE b.cash_acct_code = c.account_code
	  AND c.inactive_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 40112) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 397, 5 ) + " -- MSG: " + "check if account is invalid for the apply date"
      INSERT #ewerror
	  SELECT 4000,
			 40112,
			 b.cash_acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt b, glchart c
	  WHERE b.cash_acct_code = c.account_code
	  AND ((b.date_applied < c.active_date
	        AND c.active_date != 0)
	  OR (b.date_applied > c.inactive_date
	       AND c.inactive_date != 0))
END



IF (SELECT err_type FROM apedterr WHERE err_code = 40114) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 422, 5 ) + " -- MSG: " + "check if on-account account is inactive"
      INSERT #ewerror
	  SELECT 4000,
			 40114,
			 c.on_acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt b, appymeth c, glchart d
	  WHERE b.payment_code = c.payment_code
	  AND c.on_acct_code = d.account_code
	  AND d.inactive_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 40115) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 445, 5 ) + " -- MSG: " + "check if on-account account is invalid for the apply date"
      INSERT #ewerror
	  SELECT 4000,
			 40115,
			 c.on_acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt b, appymeth c, glchart d
	  WHERE b.payment_code = c.payment_code
	  AND c.on_acct_code = d.account_code
	  AND ((b.date_applied < d.active_date
	        AND d.active_date != 0)
	  OR (b.date_applied > d.inactive_date
	       AND d.inactive_date != 0))
END



IF (SELECT err_type FROM apedterr WHERE err_code = 40120) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 471, 5 ) + " -- MSG: " + "Check if date entered <= 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 40120,
			 "",
			 "",
			 date_entered,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt 
  	  WHERE date_entered <= 0
END




IF (SELECT err_type FROM apedterr WHERE err_code = 40130) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 496, 5 ) + " -- MSG: " + "Check if date applied <= 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 40130,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt 
  	  WHERE date_applied <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 40140) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 519, 5 ) + " -- MSG: " + "Check if applied to future period"
	


      INSERT #ewerror
	  SELECT 4000,
			 40140,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt b, apco c
  	  WHERE b.date_applied > c.period_end_date
END


IF (SELECT err_type FROM apedterr WHERE err_code = 40150) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 542, 5 ) + " -- MSG: " + "Check if applied to prior period"
	


      INSERT #ewerror
	  SELECT 4000,
			 40150,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt b, glprd c, apco d
  	  WHERE b.date_applied < c.period_start_date
	  AND c.period_end_date = d.period_end_date
END


IF (SELECT err_type FROM apedterr WHERE err_code = 40170) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 566, 5 ) + " -- MSG: " + "Check if applied period exists"
	


      UPDATE #appavpyt
      SET flag = 1
	  FROM #appavpyt, glprd c
  	  WHERE #appavpyt.date_applied BETWEEN c.period_start_date AND c.period_end_date


      INSERT #ewerror
	  SELECT 4000,
			 40170,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt 
  	  WHERE flag = 0



     UPDATE #appavpyt
     SET flag = 0
	 WHERE flag != 0

END



IF (SELECT err_type FROM apedterr WHERE err_code = 40160) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 603, 5 ) + " -- MSG: " + "Check if date applied in valid apco range"
	


      INSERT #ewerror
	  SELECT 4000,
			 40160,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt b, apco c
  	  WHERE abs(b.date_applied - b.date_entered) > c.date_range_verify
END

  


IF (SELECT err_type FROM apedterr WHERE err_code = 40210) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 628, 5 ) + " -- MSG: " + "Check if vendor code exists"
	


















	INSERT #ewerror
	  SELECT 4000,
			 40210,
			 a.vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt a
		LEFT JOIN apvend b ON a.vendor_code = b.vendor_code
	  WHERE b.vendor_code IS NULL


END


IF (SELECT err_type FROM apedterr WHERE err_code = 40240) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 670, 5 ) + " -- MSG: " + "Check if pay_to_code exists"
	






















      INSERT #ewerror
	  SELECT 4000,
			 40240,
			 b.pay_to_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #appavpyt b
		LEFT JOIN apvnd_vw c ON b.vendor_code = c.vendor_code AND b.pay_to_code = c.pay_to_code 
	  WHERE b.pay_to_code != "" AND c.vendor_code IS NULL


END







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appahdr1.cpp" + ", line " + STR( 719, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appahdr1_sp] TO [public]
GO
