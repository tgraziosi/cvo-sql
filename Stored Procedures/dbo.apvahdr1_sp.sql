SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[apvahdr1_sp] @error_level smallint, @debug_level smallint = 0
AS
	DECLARE @ib_flag		INTEGER

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 41, 5 ) + " -- ENTRY: "
SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco


UPDATE  #apvavchg
SET     interbranch_flag = 1
FROM 	#apvavchg a, #apvavcdt b 
WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
AND   	a.org_id <> b.org_id




IF @ib_flag = 1 
BEGIN
	



	IF (SELECT err_type FROM apedterr WHERE err_code = 31240) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 64, 5 ) + " -- MSG: " + "Validate a relationship exists for all organizations in an inter-organization trx in apinpchg/apinpcdt"

		
		UPDATE 	#apvavchg
	        SET 	temp_flag = 0

		
		UPDATE 	#apvavchg
	        SET 	temp_flag = 1
		FROM 	#apvavchg a, #apvavcdt b, OrganizationOrganizationRel oor
		WHERE 	a.org_id = oor.controlling_org_id			
		AND 	b.org_id = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	31240, 			a.org_id + ' - ' + b.org_id,
			a.org_id, 		user_id, 		0.0,
			0, 			a.trx_ctrl_num, 	b.sequence_id,
			'', 			0
		FROM 	#apvavchg a,  #apvavcdt b
		WHERE 	a.interbranch_flag = 1
		AND 	a.temp_flag = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id
		AND     b.rec_company_code = a.company_code			
	END


	



	IF (SELECT err_type FROM apedterr WHERE err_code = 31260) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 106, 5 ) + " -- MSG: " + "Validate organization exists and is active in Header"
		UPDATE 	#apvavchg
		SET 	temp_flag = 0

		UPDATE 	#apvavchg
		SET 	temp_flag = 1
 		FROM 	#apvavchg a, Organization ood
		WHERE 	a.org_id = ood.organization_id
		AND  	ood.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	31260, 		org_id,
			org_id, 		user_id, 	0.0,
			0, 			trx_ctrl_num, 	0,
			"", 			0
		FROM 	#apvavchg
		WHERE 	temp_flag = 0

	END

END



IF (SELECT err_type FROM apedterr WHERE err_code = 30020) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 137, 5 ) + " -- MSG: " + "Validate apply_to_num exists in apvohdr or is blank"
	


	      INSERT #ewerror
		  SELECT 4000,
		  		 30020,
				 apply_to_num,
				 "",
				 0,
				 0.0,
				 1,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apvavchg
	  	  WHERE apply_to_num != ""
		  AND apply_to_num NOT IN (SELECT trx_ctrl_num FROM apvohdr)
END

  
IF (SELECT err_type FROM apedterr WHERE err_code = 30030) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 161, 5 ) + " -- MSG: " + "Validate user_trx_type_code exists in apusrtyp or is blank"
	


	      INSERT #ewerror
		  SELECT 4000,
				 30030,
				 user_trx_type_code,
				 "",
				 0,
				 0.0,
				 1,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apvavchg 
	  	  WHERE user_trx_type_code != ""
		  AND user_trx_type_code NOT IN (SELECT user_trx_type_code
										   FROM apusrtyp)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 30410) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 187, 5 ) + " -- MSG: " + "Check if fob code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 30410,
			 fob_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg 
  	  WHERE fob_code NOT IN (SELECT fob_code FROM apfob)
	  AND fob_code != ""
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30400) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 211, 5 ) + " -- MSG: " + "Check if fob code is not the default"
	


      INSERT #ewerror
	  SELECT 4000,
			 30400,
			 b.fob_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b, apfob c, apvend d
  	  WHERE b.fob_code = c.fob_code
	  AND b.vendor_code = d.vendor_code
	  AND b.fob_code != d.fob_code
	  AND b.pay_to_code = ""


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 234, 5 ) + " -- MSG: " + "Check if fob code is not the default"
	


      INSERT #ewerror
	  SELECT 4000,
			 30400,
			 b.fob_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b, apfob c, appayto d
  	  WHERE b.fob_code = c.fob_code
	  AND b.vendor_code = d.vendor_code
	  AND b.pay_to_code = d.pay_to_code
	  AND b.fob_code != d.fob_code
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30420) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 260, 5 ) + " -- MSG: " + "Check if terms code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 30420,
			 terms_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg 
  	  WHERE terms_code NOT IN (SELECT terms_code FROM apterms)
	  AND terms_code != ""
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30430) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 284, 5 ) + " -- MSG: " + "Check if terms code is not the default"
	


      INSERT #ewerror
	  SELECT 4000,
			 30430,
			 b.terms_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b, apterms c, apvend d
  	  WHERE b.terms_code = c.terms_code
	  AND b.vendor_code = d.vendor_code
	  AND b.terms_code != d.terms_code
	  AND b.pay_to_code = ""

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 306, 5 ) + " -- MSG: " + "Check if terms code is not the default"
	


      INSERT #ewerror
	  SELECT 4000,
			 30430,
			 b.terms_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b, apterms c, appayto d
  	  WHERE b.terms_code = c.terms_code
	  AND b.vendor_code = d.vendor_code
	  AND b.pay_to_code = d.pay_to_code
	  AND b.terms_code != d.terms_code

END




IF (SELECT err_type FROM apedterr WHERE err_code = 30540) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 335, 5 ) + " -- MSG: " + "Check if posted flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 30540,
			 "",
			 "",
			 posted_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b
  	  WHERE posted_flag != 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30560) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 358, 5 ) + " -- MSG: " + "Check if hold flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 30560,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg 
  	  WHERE hold_flag NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30550) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 381, 5 ) + " -- MSG: " + "Check if voucher is on hold"
	


      INSERT #ewerror
	  SELECT 4000,
			 30550,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,	
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg 
  	  WHERE hold_flag = 1
END

IF (SELECT err_type FROM apedterr WHERE err_code = 30050) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 403, 5 ) + " -- MSG: " + "Check if date applied <= 0"
	


      INSERT #ewerror
	  SELECT 4000,
			 30050,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg 
  	  WHERE date_applied <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30060) <= @error_level
BEGIN
   	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 426, 5 ) + " -- MSG: " + "Check if applied to future period"
	


      INSERT #ewerror
	  SELECT 4000,
			 30060,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b, apco c
  	  WHERE b.date_applied > c.period_end_date
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30070) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 449, 5 ) + " -- MSG: " + "Check if applied to prior period"
	


      INSERT #ewerror
	  SELECT 4000,
			 30070,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b, glprd c, apco d
  	  WHERE b.date_applied < c.period_start_date
	  AND c.period_end_date = d.period_end_date
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30090) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 473, 5 ) + " -- MSG: " + "Check if applied period exists"
	


      UPDATE #apvavchg
      SET flag = 1
	  FROM #apvavchg, glprd c
  	  WHERE #apvavchg.date_applied BETWEEN c.period_start_date AND c.period_end_date


      INSERT #ewerror
	  SELECT 4000,
			 30090,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg 
  	  WHERE flag = 0


     UPDATE #apvavchg
     SET flag = 0
END

IF (SELECT err_type FROM apedterr WHERE err_code = 30080) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 505, 5 ) + " -- MSG: " + "Check if date applid in valid apco range"
	


      INSERT #ewerror
	  SELECT 4000,
			 30080,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b, apco c
  	  WHERE abs(b.date_applied - b.date_entered) > c.date_range_verify
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30100) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 528, 5 ) + " -- MSG: " + "Check if date aging is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 30100,
			 "",
			 "",
			 date_aging,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvavchg b
  	  WHERE date_aging < 0
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvahdr1.cpp" + ", line " + STR( 549, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvahdr1_sp] TO [public]
GO
