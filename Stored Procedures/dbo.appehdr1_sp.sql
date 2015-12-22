SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[appehdr1_sp] @error_level smallint, @called_from smallint = 0, @debug_level smallint = 0
WITH RECOMPILE
AS
	DECLARE @ib_flag		INTEGER

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 36, 5 ) + ' -- ENTRY: '

SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco


UPDATE  #appyvpyt
SET     interbranch_flag = 1
FROM 	#appyvpyt a, #appyvpdt b 
WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
AND   	a.org_id <> b.org_id




IF @ib_flag = 1 
BEGIN
	




	



	IF (SELECT err_type FROM apedterr WHERE err_code = 890) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 65, 5 ) + ' -- MSG: ' + 'Validate a relationship exists for all organizations in an inter-organization trx in apinpchg/apinpcdt'

		
		UPDATE 	#appyvpdt
	        SET 	temp_flag = 0

		
		UPDATE 	#appyvpdt
	        SET 	temp_flag = 1
		FROM 	#appyvpyt a, #appyvpdt b, OrganizationOrganizationRel oor
		WHERE 	a.org_id = oor.controlling_org_id			
		AND 	b.org_id = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	890, 			a.org_id + ' - ' + b.org_id,
			a.org_id, 		user_id, 		0.0,
			0, 			a.trx_ctrl_num, 	b.sequence_id,
			'', 			0
		FROM 	#appyvpyt a,  #appyvpdt b
		WHERE 	a.interbranch_flag = 1
		AND 	b.temp_flag = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id
	END


	



	IF (SELECT err_type FROM apedterr WHERE err_code = 910) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 106, 5 ) + ' -- MSG: ' + 'Validate organization exists and is active in Header'
		UPDATE 	#appyvpyt
		SET 	temp_flag = 0

		UPDATE 	#appyvpyt
		SET 	temp_flag = 1
 		FROM 	#appyvpyt a, Organization ood
		WHERE 	a.org_id = ood.organization_id
		AND  	ood.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	910, 		org_id,
			org_id, 		user_id, 	0.0,
			0, 			trx_ctrl_num, 	0,
			'', 			0
		FROM 	#appyvpyt
		WHERE 	temp_flag = 0

	END

	





























END
	
IF (SELECT err_type FROM apedterr WHERE err_code = 10) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 165, 5 ) + ' -- MSG: ' + 'Validate trxctrlnum does not exist in appyhdr'
	


      INSERT #ewerror
	  SELECT 4000,
			 10,
			 a.trx_ctrl_num,
			 '',
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt a, appyhdr b
  	  WHERE a.trx_ctrl_num = b.trx_ctrl_num
	  AND a.payment_type != 3
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 189, 5 ) + ' -- MSG: ' + 'Check if doc_ctrl_num is blank for a manual check'
   


      INSERT #ewerror
	  SELECT 4000,
			 30,
			 b.doc_ctrl_num,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, appymeth c
  	  WHERE b.payment_code = c.payment_code
	  AND c.payment_type = 1
	  AND b.doc_ctrl_num = ''
	  AND b.hold_flag = 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 35) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 215, 5 ) + ' -- MSG: ' + 'Check if doc_ctrl_num is blank for a manual check on hold'
   


      INSERT #ewerror
	  SELECT 4000,
			 35,
			 b.doc_ctrl_num,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, appymeth c
  	  WHERE b.payment_code = c.payment_code
	  AND c.payment_type = 1
	  AND b.doc_ctrl_num = ''
	  AND b.hold_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 40) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 242, 5 ) + ' -- MSG: ' + 'Check if doc_ctrl_num is blank for a printed system check'
	


      INSERT #ewerror
	  SELECT 4000,
			 40,
			 b.doc_ctrl_num,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, appymeth c
  	  WHERE b.payment_code = c.payment_code
	  AND c.payment_type = 2
	  AND b.printed_flag = 1
	  AND b.doc_ctrl_num = ''
END



IF (SELECT err_type FROM apedterr WHERE err_code = 50) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 269, 5 ) + ' -- MSG: ' + 'Check if doc_ctrl_num is not blank for a unprinted system check'
	


      INSERT #ewerror
	  SELECT 4000,
			 50,
			 b.doc_ctrl_num,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, appymeth c
  	  WHERE b.payment_code = c.payment_code
	  AND c.payment_type = 2
	  AND b.printed_flag = 0
	  AND b.doc_ctrl_num != ''
END


IF (SELECT err_type FROM apedterr WHERE err_code = 60) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 295, 5 ) + ' -- MSG: ' + 'Check if doc_ctrl_num is not blank for a bank check'
	


      INSERT #ewerror
	  SELECT 4000,
			 60,
			 b.doc_ctrl_num,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, appymeth c
  	  WHERE b.payment_code = c.payment_code
	  AND c.payment_type = 3
	  AND b.doc_ctrl_num != ''
END


IF ((SELECT batch_proc_flag FROM apco) = 1)
  BEGIN

   IF (SELECT err_type FROM apedterr WHERE err_code = 70) <= @error_level
     BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 323, 5 ) + ' -- MSG: ' + 'Check batch code is blank'
		


      INSERT #ewerror
	  SELECT 4000,
			 70,
			 batch_code,
			 '',
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt 
  	  WHERE batch_code = ''
    END
END



IF (SELECT err_type FROM apedterr WHERE err_code = 80) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 348, 5 ) + ' -- MSG: ' + 'Check cash_acct_code is blank'
	


      INSERT #ewerror
	  SELECT 4000,
			 80,
			 cash_acct_code,
			 '',
			 0,
			 0.0,
			 1,
	    	 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt 
	  WHERE cash_acct_code = ''
	  AND payment_type IN (1,2)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 90) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 372, 5 ) + ' -- MSG: ' + 'Check cash_acct_code exists in apcash'
	


      INSERT #ewerror
	  SELECT 4000,
			 90,
			 cash_acct_code,
			 '',
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt 
  	  WHERE payment_type IN (1,2)
	  AND cash_acct_code NOT IN (SELECT cash_acct_code FROM apcash)
	  AND cash_acct_code != ''
END


IF (SELECT err_type FROM apedterr WHERE err_code = 100) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 397, 5 ) + ' -- MSG: ' + 'Check cash_acct_code exists in glchart'
	


      INSERT #ewerror
	  SELECT 4000,
			 100,
			 cash_acct_code,
			 '',
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt 
  	  WHERE payment_type IN (1,2)
	  AND cash_acct_code NOT IN (SELECT account_code FROM glchart)
	  AND cash_acct_code != ''
END


IF (SELECT err_type FROM apedterr WHERE err_code = 111) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 422, 5 ) + ' -- MSG: ' + 'check if cash account is inactive'
      INSERT #ewerror
	  SELECT 4000,
			 111,
			 b.cash_acct_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, glchart c
	  WHERE b.cash_acct_code = c.account_code
	  AND c.inactive_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 112) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 444, 5 ) + ' -- MSG: ' + 'check if account is invalid for the apply date'
      INSERT #ewerror
	  SELECT 4000,
			 112,
			 b.cash_acct_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, glchart c
	  WHERE b.cash_acct_code = c.account_code
	  AND ((b.date_applied < c.active_date
	        AND c.active_date != 0)
	  OR (b.date_applied > c.inactive_date
	       AND c.inactive_date != 0))
END



IF (SELECT err_type FROM apedterr WHERE err_code = 114) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 469, 5 ) + ' -- MSG: ' + 'check if on-account account is inactive'
      INSERT #ewerror
	  SELECT 4000,
			 114,
			 c.on_acct_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, appymeth c, glchart d
	  WHERE b.payment_code = c.payment_code
	  AND c.on_acct_code = d.account_code
	  AND d.inactive_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 115) <= @error_level
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 492, 5 ) + ' -- MSG: ' + 'check if on-account account is invalid for the apply date'
      INSERT #ewerror
	  SELECT 4000,
			 115,
			 c.on_acct_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, appymeth c, glchart d
	  WHERE b.payment_code = c.payment_code
	  AND c.on_acct_code = d.account_code
	  AND ((b.date_applied < d.active_date
	        AND d.active_date != 0)
	  OR (b.date_applied > d.inactive_date
	       AND d.inactive_date != 0))
END





IF (SELECT err_type FROM apedterr WHERE err_code = 110) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 520, 5 ) + ' -- MSG: ' + 'Check cash_acct_code is the vendors default'
	


      INSERT #ewerror
	  SELECT 4000,
			 110,
			 b.cash_acct_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, apvend c
  	  WHERE b.vendor_code = c.vendor_code
	  AND b.cash_acct_code != c.cash_acct_code
	  AND b.payment_type = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 120) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 546, 5 ) + ' -- MSG: ' + 'Check if date entered <= 0'
	


      INSERT #ewerror
	  SELECT 4000,
			 120,
			 '',
			 '',
			 date_entered,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt 
  	  WHERE date_entered <= 0
END




IF (SELECT err_type FROM apedterr WHERE err_code = 130) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 571, 5 ) + ' -- MSG: ' + 'Check if date applied <= 0'
	


      INSERT #ewerror
	  SELECT 4000,
			 130,
			 '',
			 '',
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt 
  	  WHERE date_applied <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 140) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 594, 5 ) + ' -- MSG: ' + 'Check if applied to future period'
	


      INSERT #ewerror
	  SELECT 4000,
			 140,
			 '',
			 '',
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, apco c
  	  WHERE b.date_applied > c.period_end_date
END


IF (SELECT err_type FROM apedterr WHERE err_code = 150) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 617, 5 ) + ' -- MSG: ' + 'Check if applied to prior period'
	


      INSERT #ewerror
	  SELECT 4000,
			 150,
			 '',
			 '',
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, glprd c, apco d
  	  WHERE b.date_applied < c.period_start_date
	  AND c.period_end_date = d.period_end_date
END


IF (SELECT err_type FROM apedterr WHERE err_code = 170) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 641, 5 ) + ' -- MSG: ' + 'Check if applied period exists'
	


      UPDATE #appyvpyt
      SET flag = 1
	  FROM #appyvpyt, glprd c
  	  WHERE #appyvpyt.date_applied BETWEEN c.period_start_date AND c.period_end_date


      INSERT #ewerror
	  SELECT 4000,
			 170,
			 '',
			 '',
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt 
  	  WHERE flag = 0



     UPDATE #appyvpyt
     SET flag = 0
	 WHERE flag != 0

END



IF (SELECT err_type FROM apedterr WHERE err_code = 160) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 678, 5 ) + ' -- MSG: ' + 'Check if date applied in valid apco range'
	


      INSERT #ewerror
	  SELECT 4000,
			 160,
			 '',
			 '',
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #appyvpyt b, apco c
  	  WHERE abs(b.date_applied - b.date_entered) > c.date_range_verify
END



IF (SELECT err_type FROM apedterr WHERE err_code = 860) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 702, 5 ) + ' -- MSG: ' + 'Check if doc_ctrl_num is a duplicate in the unposted table'
	


      INSERT #ewerror
	  SELECT 4000,
			 860,
			 b.doc_ctrl_num,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM apinppyt a, #appyvpyt b
  	  WHERE b.payment_type = 1
	  AND b.doc_ctrl_num != ''
	  AND b.trx_type IN (4111, 4011)
	  AND a.doc_ctrl_num = b.doc_ctrl_num
	  AND a.cash_acct_code = b.cash_acct_code
	  AND a.trx_ctrl_num != b.trx_ctrl_num
END


IF (SELECT err_type FROM apedterr WHERE err_code = 870) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 730, 5 ) + ' -- MSG: ' + 'Check if doc_ctrl_num is a duplicate in the posted table'
	


      INSERT #ewerror
	  SELECT 4000,
			 870,
			 b.doc_ctrl_num,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM appyhdr a, #appyvpyt b
  	  WHERE b.payment_type = 1
	  AND b.doc_ctrl_num != ''
	  AND a.doc_ctrl_num = b.doc_ctrl_num
	  AND a.cash_acct_code = b.cash_acct_code
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appehdr1.cpp' + ', line ' + STR( 755, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appehdr1_sp] TO [public]
GO
