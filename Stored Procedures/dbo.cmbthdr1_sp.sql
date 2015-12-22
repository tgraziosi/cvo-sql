SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE PROCEDURE [dbo].[cmbthdr1_sp] @error_level smallint, @debug_level smallint = 0
AS
  DECLARE 
  	@batch_proc_flag		smallint,
   	@home_cur				varchar(8),
	@oper_cur				varchar(8),
	@rate_type_home			varchar(8),
	@rate_type_oper			varchar(8),
	@rate_home				float,
	@rate_oper				float


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "

DECLARE @ib_flag		INTEGER


SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco


UPDATE  a
SET     a.interbranch_flag = 1
FROM 	#cmbtvhdr a, #cmbtvhdr b 
WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
AND   	a.from_org_id <> b.to_org_id




IF @ib_flag = 1 
BEGIN
	




	IF (SELECT err_type FROM cmedterr WHERE err_code = 40320) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 63, 5 ) + " -- MSG: " + "Validate a relationship exists for all organizations in an inter-organization trx in cminpbtr"

		

		
		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 0

		



		UPDATE 	a
	        SET 	a.temp_flag = 1
		FROM 	#cmbtvhdr a, #cmbtvhdr b, OrganizationOrganizationRel oor
		WHERE 	a.from_org_id  = oor.controlling_org_id			
		AND 	b.to_org_id    = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

		





		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	7000, 	40320, 			a.from_org_id + ' - ' + b.to_org_id,
			a.from_org_id, 		a.user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	0,
			'', 			0
		FROM 	#cmbtvhdr a,  #cmbtvhdr b
		WHERE 	a.interbranch_flag = 1
		AND 	a.temp_flag = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.from_org_id <> b.to_org_id
	END

	



	IF (SELECT err_type FROM cmedterr WHERE err_code = 40330) <= @error_level
  	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 111, 5 ) + " -- MSG: " + "Validate if account mapping exists"
		


		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 0

		




		UPDATE 	a
		SET 	a.temp_flag = 1
		FROM 	#cmbtvhdr a, #cmbtvhdr b, OrganizationOrganizationDef ood
		WHERE 	a.from_org_id 	= ood.controlling_org_id
		AND 	b.to_org_id 	= ood.detail_org_id
		AND	a.trx_ctrl_num 	= b.trx_ctrl_num
		AND 	a.from_expense_account_code LIKE ood.account_mask			


		






		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 7000,	40330,		a.from_expense_account_code,
			'',			0,		0.0,
			1,			a.trx_ctrl_num,	0,
			'',			0
		FROM 	#cmbtvhdr a, #cmbtvhdr b
		WHERE 	b.interbranch_flag = 1
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND 	a.temp_flag = 0
		AND   	a.from_org_id <> b.to_org_id
	END

	



	IF (SELECT err_type FROM cmedterr WHERE err_code = 40330) <= @error_level
  	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 162, 5 ) + " -- MSG: " + "Validate if account mapping exists"
		


		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 0

		




		UPDATE 	a
		SET 	a.temp_flag = 1
		FROM 	#cmbtvhdr a, #cmbtvhdr b, OrganizationOrganizationDef ood
		WHERE 	a.from_org_id 	= ood.controlling_org_id
		AND 	b.to_org_id 	= ood.detail_org_id
		AND	a.trx_ctrl_num 	= b.trx_ctrl_num
		AND 	a.to_expense_account_code LIKE ood.account_mask			


		






		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 7000,	40330,		a.to_expense_account_code,
			'',			0,		0.0,
			1,			a.trx_ctrl_num,	0,
			'',			0
		FROM 	#cmbtvhdr a, #cmbtvhdr b
		WHERE 	b.interbranch_flag = 1
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND 	a.temp_flag = 0
		AND   	a.from_org_id <> b.to_org_id
	END

	



	IF (SELECT err_type FROM cmedterr WHERE err_code = 40340) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 216, 5 ) + " -- MSG: " + "Validate From Organization exists and is active"
		UPDATE 	#cmbtvhdr
		SET 	temp_flag = 0

		UPDATE 	a
		SET 	a.temp_flag = 1
 		FROM 	#cmbtvhdr a, Organization ood
		WHERE 	a.from_org_id = ood.organization_id
		AND  	ood.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	7000, 	40340, 		from_org_id,
			from_org_id, 		user_id, 	0.0,
			1, 			trx_ctrl_num, 	0,
			"", 			0
		FROM 	#cmbtvhdr
		WHERE 	temp_flag = 0

	END

	



	IF (SELECT err_type FROM cmedterr WHERE err_code = 40350) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 250, 5 ) + " -- MSG: " + "Validate To Organization exists and is active"
		UPDATE 	#cmbtvhdr
		SET 	temp_flag = 0

		UPDATE 	a
		SET 	a.temp_flag = 1
 		FROM 	#cmbtvhdr a, Organization ood
		WHERE 	a.to_org_id = ood.organization_id
		AND  	ood.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	7000, 	40350, 		to_org_id,
			to_org_id, 		user_id, 	0.0,
			1, 			trx_ctrl_num, 	0,
			"", 			0
		FROM 	#cmbtvhdr
		WHERE 	temp_flag = 0
	END

	



	IF (SELECT err_type FROM cmedterr WHERE err_code = 40360) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \cmbthdr1"

		


		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 0

		



		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 1
		FROM 	#cmbtvhdr a
		WHERE  dbo.IBOrgbyAcct_fn(a.from_expense_account_code)  = a.from_org_id 
				




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	7000, 40360, 		from_expense_account_code,
			from_org_id, 		0, 			0.0,
			1, 			trx_ctrl_num, 	0,
			'', 			0
		FROM 	#cmbtvhdr
		WHERE 	temp_flag = 0
	END	-- AAP

	



	IF (SELECT err_type FROM cmedterr WHERE err_code = 40360) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \cmbthdr1"

		


		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 0

		



		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 1
		FROM 	#cmbtvhdr a
		WHERE  dbo.IBOrgbyAcct_fn(a.to_expense_account_code)  = a.to_org_id

                




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	7000, 40360, 		to_expense_account_code,
			to_org_id, 		0, 			0.0,
			1, 			trx_ctrl_num, 	0,
			'', 			0
		FROM 	#cmbtvhdr
		WHERE 	temp_flag = 0
	END	-- AAP


END

ELSE
BEGIN
	


	IF (SELECT err_type FROM cmedterr WHERE err_code = 40370) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same \cmmtdet1"
		


		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 0

		



		UPDATE 	#cmbtvhdr
	        SET 	temp_flag = 1
		FROM 	#cmbtvhdr
		WHERE 	from_org_id = to_org_id

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	7000, 	40370, 			from_org_id +'-'+ to_org_id,
			from_org_id, 		0, 			0.0,
			1, 			trx_ctrl_num, 	0,
			'', 			0
		FROM 	#cmbtvhdr 
		WHERE	temp_flag = 0
	END	
END	--AAP

SELECT 	@batch_proc_flag = batch_proc_flag,
		@rate_type_home = rate_type_home,
		@rate_type_oper = rate_type_oper
FROM cmco  

SELECT @home_cur = home_currency,
	   @oper_cur = oper_currency
FROM glco


CREATE TABLE #rates (from_currency varchar(8),
				   to_currency varchar(8),
				   rate_type varchar(8),
				   date_applied int,
				   rate float)
IF @@error <> 0
   RETURN -1

INSERT #rates (from_currency,
				 to_currency,
				 rate_type,
				 date_applied,
				 rate)
SELECT DISTINCT currency_code_from,
		 	    @home_cur,
				@rate_type_home,
				date_applied,
			    0.0E0
FROM #cmbtvhdr
WHERE ((date_applied) > (0.0) + 0.0000001)
AND rate_type_home = ''

INSERT #rates (from_currency,
				 to_currency,
				 rate_type,
				 date_applied,
				 rate)
SELECT DISTINCT currency_code_to,
		 	    @oper_cur,
				@rate_type_oper,
				date_applied,
			    0.0E0
FROM #cmbtvhdr
WHERE ((date_applied) > (0.0) + 0.0000001)
AND rate_type_oper = ''

EXEC CVO_Control..mcrates_sp


IF (@batch_proc_flag = 1)
   BEGIN
	IF (SELECT err_type FROM cmedterr WHERE err_code = 40010) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 468, 5 ) + " -- MSG: " + "Validate batch_code exists"
		


	      INSERT #ewerror
		  SELECT 7000,
		  		 40010,
		  		 batch_code,
		  		 "",
				 0,
				 0.0,
				 1,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #cmbtvhdr 
	  	  WHERE batch_code NOT IN (SELECT batch_ctrl_num
								   FROM batchctl)
 	END
   END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40110) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 492, 5 ) + " -- MSG: " + "Check if posted flag is valid"
	


      INSERT #ewerror
	  SELECT 7000,
			 40110,
			 "",
			 "",
			 posted_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr b
  	  WHERE posted_flag != 0
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40130) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 514, 5 ) + " -- MSG: " + "Check if hold flag is valid"
	


      INSERT #ewerror
	  SELECT 7000,
	  		 40130,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr 
  	  WHERE hold_flag NOT IN (0,1)
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 40120) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 537, 5 ) + " -- MSG: " + "Check if trx is on hold"
	


      INSERT #ewerror
	  SELECT 7000,
			 40120,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,	
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr
  	  WHERE hold_flag = 1
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 40020) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 561, 5 ) + " -- MSG: " + "Check if date applied <= 0"
	


      INSERT #ewerror
	  SELECT 7000,
			 40020,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr
  	  WHERE date_applied <= 0
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 40030) <= @error_level
BEGIN
   	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 584, 5 ) + " -- MSG: " + "Check if applied to future period"
	


      INSERT #ewerror
	  SELECT 7000,
			 40030,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr b, cmco c
  	  WHERE b.date_applied > c.period_end_date
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 40040) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 607, 5 ) + " -- MSG: " + "Check if applied to prior period"
	


      INSERT #ewerror
	  SELECT 7000,
			 40040,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr b, glprd c, cmco d
  	  WHERE b.date_applied < c.period_start_date
	  AND c.period_end_date = d.period_end_date
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 40060) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 631, 5 ) + " -- MSG: " + "Check if applied period exists"
	


      UPDATE #cmbtvhdr
      SET flag = 1
	  FROM #cmbtvhdr, glprd c
  	  WHERE #cmbtvhdr.date_applied BETWEEN c.period_start_date AND c.period_end_date


      INSERT #ewerror
	  SELECT 7000,
			 40060,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr
  	  WHERE flag = 0


     UPDATE #cmbtvhdr
     SET flag = 0
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 40050) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 665, 5 ) + " -- MSG: " + "Check if date applid in valid cmco range"
	


      INSERT #ewerror
	  SELECT 7000,
			 40050,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr b, cmco c
  	  WHERE abs(b.date_applied - b.date_entered) > c.date_range_verify
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 40080) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 689, 5 ) + " -- MSG: " + "Validate currency code from exists"
	


      INSERT #ewerror
	  SELECT 7000,
			 40080,
			 currency_code_from,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr
  	  WHERE currency_code_from NOT IN (SELECT currency_code FROM glcurr_vw)
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 40080) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 713, 5 ) + " -- MSG: " + "Validate currency code to exists"
	


      INSERT #ewerror
	  SELECT 7000,
			 40080,
			 currency_code_to,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr
  	  WHERE currency_code_to NOT IN (SELECT currency_code FROM glcurr_vw)
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 40095) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 737, 5 ) + " -- MSG: " + "Validate rate_home exists"
	



	UPDATE #cmbtvhdr
	SET rate_home = b.rate
	FROM #cmbtvhdr a, #rates b
	WHERE a.currency_code_from = b.from_currency
	AND b.to_currency = @home_cur
	AND a.date_applied = b.date_applied
	AND a.rate_type_home = b.rate_type
	AND a.rate_home = 0.0
	
      INSERT #ewerror
	  SELECT 7000,
			 40095,
			 "",
			 "",
			 0,
			 rate_home,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr
  	  WHERE (ABS((rate_home)-(0.0)) < 0.0000001)
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 40105) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 771, 5 ) + " -- MSG: " + "Validate rate_oper exists"
	


	UPDATE #cmbtvhdr
	SET rate_oper = b.rate
	FROM #cmbtvhdr a, #rates b
	WHERE a.currency_code_to = b.from_currency
	AND b.to_currency = @oper_cur
	AND a.date_applied = b.date_applied
	AND a.rate_type_oper = b.rate_type
	AND a.rate_oper = 0.0

      INSERT #ewerror
	  SELECT 7000,
			 40105,
			 "",
			 "",
			 0,
			 rate_oper,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr
  	  WHERE (ABS((rate_oper)-(0.0)) < 0.0000001)
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 40150) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 804, 5 ) + " -- MSG: " + "Validate bank transfer accounts are different"
	


      INSERT #ewerror
	  SELECT 7000,
			 40150,
			 cash_acct_code_from,
			 cash_acct_code_to,
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmbtvhdr
  	  WHERE cash_acct_code_from = cash_acct_code_to
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40190) <= @error_level
BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 827, 5 ) + " -- MSG: " + "Check if To Cash Account reference code exists in GL"
      INSERT #ewerror
	  SELECT 7000,
			 40190,
			 to_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr b 
	  WHERE b.to_reference_code NOT IN (SELECT reference_code FROM glref)    
	  AND b.to_reference_code != ''
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40160) <= @error_level
BEGIN

  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 848, 5 ) + " -- MSG: " + "Check if To Cash Account reference code is required"
      UPDATE #cmbtvhdr
	  SET flag = 1
	  FROM #cmbtvhdr, glrefact b
	  WHERE #cmbtvhdr.cash_acct_code_to LIKE b.account_mask
	  AND b.reference_flag = 1
	  AND #cmbtvhdr.to_reference_code = ''


      INSERT #ewerror
	  SELECT 7000,
			 40160,
			 a.cash_acct_code_to,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a, glrefact b
	  WHERE
		 a.cash_acct_code_to LIKE b.account_mask
	  AND b.reference_flag = 3
	  AND a.to_reference_code = ""
	  AND a.flag = 0

	  UPDATE #cmbtvhdr
	  SET flag = 0
	  WHERE flag <> 0
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 883, 5 ) + " -- MSG: " + "Check if To Cash Account reference code is excluded invalid"
	  



      UPDATE #cmbtvhdr
	  SET flag = 1
	  FROM #cmbtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmbtvhdr.cash_acct_code_to LIKE c.account_mask
	  AND #cmbtvhdr.to_reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag = 1
	  AND d.reference_type = b.reference_type
	  AND #cmbtvhdr.to_reference_code != ""

IF (SELECT err_type FROM cmedterr WHERE err_code = 40170) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40170,
			 to_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 1
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 921, 5 ) + " -- MSG: " + "Check if To Cash Account reference code is not allowed"
	  


      UPDATE #cmbtvhdr
	  SET flag = 2
	  FROM #cmbtvhdr, glrefact b
	  WHERE #cmbtvhdr.cash_acct_code_to LIKE b.account_mask
	  AND #cmbtvhdr.to_reference_code != ""
	  AND b.reference_flag IN (2,3)
	  AND #cmbtvhdr.flag = 0

IF (SELECT err_type FROM cmedterr WHERE err_code = 40170) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40170,
			 a.to_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 0
	  AND a.to_reference_code != ""
END


	 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 960, 5 ) + " -- MSG: " + "Check if To Cash Account reference code is required or optional and invalid"
	  


      UPDATE #cmbtvhdr
	  SET flag = 3
	  FROM #cmbtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmbtvhdr.cash_acct_code_to LIKE c.account_mask
	  AND #cmbtvhdr.to_reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag IN (2,3)
	  AND d.reference_type = b.reference_type
	  AND #cmbtvhdr.to_reference_code != ""
	  AND #cmbtvhdr.flag = 2

IF (SELECT err_type FROM cmedterr WHERE err_code = 40180) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40180,
			 a.to_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 2
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40230) <= @error_level
BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 999, 5 ) + " -- MSG: " + "Check if To Expense Acct Reference  code exists in GL"
      INSERT #ewerror
	  SELECT 7000,
			 40230,
			 to_expense_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr b 
	  WHERE b.to_expense_reference_code NOT IN (SELECT reference_code FROM glref)    
	  AND b.to_expense_reference_code != ''
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40200) <= @error_level
BEGIN

  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1020, 5 ) + " -- MSG: " + "Check if To Expense Acct Reference  code is required"
      UPDATE #cmbtvhdr
	  SET flag = 1
	  FROM #cmbtvhdr, glrefact b
	  WHERE #cmbtvhdr.to_expense_account_code LIKE b.account_mask
	  AND b.reference_flag = 1
	  AND #cmbtvhdr.to_expense_reference_code = ''


      INSERT #ewerror
	  SELECT 7000,
			 40200,
			 a.to_expense_account_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a, glrefact b
	  WHERE
		 a.to_expense_account_code LIKE b.account_mask
	  AND b.reference_flag = 3
	  AND a.to_expense_reference_code = ""
	  AND a.flag = 0

	  UPDATE #cmbtvhdr
	  SET flag = 0
	  WHERE flag <> 0
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1055, 5 ) + " -- MSG: " + "Check if To Expense Acct Reference  code is excluded invalid"
	  



      UPDATE #cmbtvhdr
	  SET flag = 1
	  FROM #cmbtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmbtvhdr.to_expense_account_code LIKE c.account_mask
	  AND #cmbtvhdr.to_expense_reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag = 1
	  AND d.reference_type = b.reference_type
	  AND #cmbtvhdr.to_expense_reference_code != ""

IF (SELECT err_type FROM cmedterr WHERE err_code = 40210) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40210,
			 to_expense_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 1
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1093, 5 ) + " -- MSG: " + "Check if To Expense Acct Reference  code is not allowed"
	  


      UPDATE #cmbtvhdr
	  SET flag = 2
	  FROM #cmbtvhdr, glrefact b
	  WHERE #cmbtvhdr.to_expense_account_code LIKE b.account_mask
	  AND #cmbtvhdr.to_expense_reference_code != ""
	  AND b.reference_flag IN (2,3)
	  AND #cmbtvhdr.flag = 0

IF (SELECT err_type FROM cmedterr WHERE err_code = 40210) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40210,
			 a.to_expense_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 0
	  AND a.to_expense_reference_code != ""
END


	 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1132, 5 ) + " -- MSG: " + "Check if To Expense Acct Reference  code is required or optional and invalid"
	  


      UPDATE #cmbtvhdr
	  SET flag = 3
	  FROM #cmbtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmbtvhdr.to_expense_account_code LIKE c.account_mask
	  AND #cmbtvhdr.to_expense_reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag IN (2,3)
	  AND d.reference_type = b.reference_type
	  AND #cmbtvhdr.to_expense_reference_code != ""
	  AND #cmbtvhdr.flag = 2

IF (SELECT err_type FROM cmedterr WHERE err_code = 40220) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40220,
			 a.to_expense_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 2
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40270) <= @error_level
BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1171, 5 ) + " -- MSG: " + "Check if From Cash Account Reference  code exists in GL"
      INSERT #ewerror
	  SELECT 7000,
			 40270,
			 from_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr b 
	  WHERE b.from_reference_code NOT IN (SELECT reference_code FROM glref)    
	  AND b.from_reference_code != ''
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40240) <= @error_level
BEGIN

  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1192, 5 ) + " -- MSG: " + "Check if From Cash Account Reference  code is required"
      UPDATE #cmbtvhdr
	  SET flag = 1
	  FROM #cmbtvhdr, glrefact b
	  WHERE #cmbtvhdr.cash_acct_code_from LIKE b.account_mask
	  AND b.reference_flag = 1
	  AND #cmbtvhdr.from_reference_code = ''


      INSERT #ewerror
	  SELECT 7000,
			 40240,
			 a.cash_acct_code_from,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a, glrefact b
	  WHERE
		 a.cash_acct_code_from LIKE b.account_mask
	  AND b.reference_flag = 3
	  AND a.from_reference_code = ""
	  AND a.flag = 0

	  UPDATE #cmbtvhdr
	  SET flag = 0
	  WHERE flag <> 0
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1227, 5 ) + " -- MSG: " + "Check if From Cash Account Reference  code is excluded invalid"
	  



      UPDATE #cmbtvhdr
	  SET flag = 1
	  FROM #cmbtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmbtvhdr.cash_acct_code_from LIKE c.account_mask
	  AND #cmbtvhdr.from_reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag = 1
	  AND d.reference_type = b.reference_type
	  AND #cmbtvhdr.from_reference_code != ""

IF (SELECT err_type FROM cmedterr WHERE err_code = 40250) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40250,
			 from_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 1
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1265, 5 ) + " -- MSG: " + "Check if From Cash Account Reference  code is not allowed"
	  


      UPDATE #cmbtvhdr
	  SET flag = 2
	  FROM #cmbtvhdr, glrefact b
	  WHERE #cmbtvhdr.cash_acct_code_from LIKE b.account_mask
	  AND #cmbtvhdr.from_reference_code != ""
	  AND b.reference_flag IN (2,3)
	  AND #cmbtvhdr.flag = 0

IF (SELECT err_type FROM cmedterr WHERE err_code = 40250) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40250,
			 a.from_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 0
	  AND a.from_reference_code != ""
END


	 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1304, 5 ) + " -- MSG: " + "Check if From Cash Account Reference  code is required or optional and invalid"
	  


      UPDATE #cmbtvhdr
	  SET flag = 3
	  FROM #cmbtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmbtvhdr.cash_acct_code_from LIKE c.account_mask
	  AND #cmbtvhdr.from_reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag IN (2,3)
	  AND d.reference_type = b.reference_type
	  AND #cmbtvhdr.from_reference_code != ""
	  AND #cmbtvhdr.flag = 2

IF (SELECT err_type FROM cmedterr WHERE err_code = 40260) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40260,
			 a.from_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 2
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 40310) <= @error_level
BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1344, 5 ) + " -- MSG: " + "Check if From Expense Account Reference  code exists in GL"
      INSERT #ewerror
	  SELECT 7000,
			 40310,
			 from_expense_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr b 
	  WHERE b.from_expense_reference_code NOT IN (SELECT reference_code FROM glref)    
	  AND b.from_expense_reference_code != ''
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 40280) <= @error_level
BEGIN

  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1365, 5 ) + " -- MSG: " + "Check if From Expense Account Reference  code is required"
      UPDATE #cmbtvhdr
	  SET flag = 1
	  FROM #cmbtvhdr, glrefact b
	  WHERE #cmbtvhdr.from_expense_account_code LIKE b.account_mask
	  AND b.reference_flag = 1
	  AND #cmbtvhdr.from_expense_reference_code = ''


      INSERT #ewerror
	  SELECT 7000,
			 40280,
			 a.from_expense_account_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a, glrefact b
	  WHERE
		 a.from_expense_account_code LIKE b.account_mask
	  AND b.reference_flag = 3
	  AND a.from_expense_reference_code = ""
	  AND a.flag = 0

	  UPDATE #cmbtvhdr
	  SET flag = 0
	  WHERE flag <> 0
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1400, 5 ) + " -- MSG: " + "Check if From Expense Account Reference  code is excluded invalid"
	  



      UPDATE #cmbtvhdr
	  SET flag = 1
	  FROM #cmbtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmbtvhdr.from_expense_account_code LIKE c.account_mask
	  AND #cmbtvhdr.from_expense_reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag = 1
	  AND d.reference_type = b.reference_type
	  AND #cmbtvhdr.from_expense_reference_code != ""

IF (SELECT err_type FROM cmedterr WHERE err_code = 40290) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40290,
			 from_expense_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 1
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1438, 5 ) + " -- MSG: " + "Check if From Expense Account Reference  code is not allowed"
	  


      UPDATE #cmbtvhdr
	  SET flag = 2
	  FROM #cmbtvhdr, glrefact b
	  WHERE #cmbtvhdr.from_expense_account_code LIKE b.account_mask
	  AND #cmbtvhdr.from_expense_reference_code != ""
	  AND b.reference_flag IN (2,3)
	  AND #cmbtvhdr.flag = 0

IF (SELECT err_type FROM cmedterr WHERE err_code = 40290) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40290,
			 a.from_expense_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 0
	  AND a.from_expense_reference_code != ""
END


	 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1477, 5 ) + " -- MSG: " + "Check if From Expense Account Reference  code is required or optional and invalid"
	  


      UPDATE #cmbtvhdr
	  SET flag = 3
	  FROM #cmbtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmbtvhdr.from_expense_account_code LIKE c.account_mask
	  AND #cmbtvhdr.from_expense_reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag IN (2,3)
	  AND d.reference_type = b.reference_type
	  AND #cmbtvhdr.from_expense_reference_code != ""
	  AND #cmbtvhdr.flag = 2

IF (SELECT err_type FROM cmedterr WHERE err_code = 40300) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 40300,
			 a.from_expense_reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmbtvhdr a
	  WHERE a.flag = 2
END


DROP TABLE #rates



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbthdr1.cpp" + ", line " + STR( 1518, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cmbthdr1_sp] TO [public]
GO
