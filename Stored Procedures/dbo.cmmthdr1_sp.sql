SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE PROCEDURE [dbo].[cmmthdr1_sp] @error_level smallint, @debug_level smallint = 0
AS
  DECLARE @batch_proc_flag		smallint
  DECLARE @ib_flag		        INTEGER        
  DECLARE @interbranch_flag             INTEGER        

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 32, 5 ) + " -- ENTRY: "

SELECT @batch_proc_flag = batch_proc_flag
FROM cmco  



SELECT @ib_flag = 0
SELECT @ib_flag = ib_flag 
FROM glco

UPDATE #cmmtvhdr
        SET interbranch_flag = 1
        FROM #cmmtvhdr a, #cmmtvdtl b
        WHERE a.trx_ctrl_num = b.trx_ctrl_num
                AND a.org_id <> b.org_id


IF @ib_flag > 0
BEGIN
        
        IF (SELECT err_type FROM apedterr WHERE err_code = 10230) <= @error_level
        BEGIN
        
                


                
                IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 60, 5 ) + " -- MSG: " + "Validate a relationship exists for all branches in an inter-branch trx in cmmanhdr/cmmandtl"        
        
                UPDATE 	#cmmtvdtl
        	SET 	temp_flag = 0
        
        	UPDATE 	#cmmtvdtl
        	SET 	temp_flag = 1
        	FROM 	#cmmtvhdr a, #cmmtvdtl b, OrganizationOrganizationRel oor
        	WHERE 	a.org_id = oor.controlling_org_id
        	AND 	b.org_id = oor.detail_org_id
        	AND     a.trx_ctrl_num = b.trx_ctrl_num
        
        	INSERT INTO #ewerror
        	(       module_id,      err_code,       info1,
        	        info2,          infoint,        infofloat,
        		flag1,          trx_ctrl_num,   sequence_id,
        		source_ctrl_num,extra
                )
        	SELECT 7000,  10230,	         a.org_id + " - " + b.org_id,
                        b.org_id,         a.hold_flag,           0.0,
                        1,                a.trx_ctrl_num,        b.sequence_id,
        	        "",               0
        	FROM 	#cmmtvhdr a, #cmmtvdtl b
        	WHERE 	a.interbranch_flag = 1
        	AND 	b.temp_flag = 0
        	AND     a.trx_ctrl_num = b.trx_ctrl_num
        	AND   	a.org_id <> b.org_id
        END

	IF (SELECT err_type FROM apedterr WHERE err_code = 10240) <= @error_level
        BEGIN
        	


        
                IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 95, 5 ) + " -- MSG: " + "Validate if account mapping exists for header"
        
        	UPDATE 	#cmmtvhdr
        	SET 	temp_flag = 0
        
        	UPDATE 	#cmmtvhdr
        	SET 	temp_flag = 1
        	FROM 	#cmmtvhdr a, OrganizationOrganizationDef ood
                WHERE 	a.org_id = ood.controlling_org_id
        		AND 	a.cash_acct_code LIKE ood.account_mask			
        
        	INSERT INTO #ewerror
        	(       module_id,      err_code,       info1,
        		info2,          infoint,        infofloat,
        		flag1,          trx_ctrl_num,   sequence_id,
        		source_ctrl_num,extra
        	)
        	SELECT 7000, 10240,     cash_acct_code,
        		org_id,         user_id,       0.0,
        		1,              trx_ctrl_num,  -1,
        		"",             0
        	FROM 	#cmmtvhdr
        	WHERE 	interbranch_flag = 1
        	        AND 	temp_flag = 0
        END

	IF (SELECT err_type FROM apedterr WHERE err_code = 10250) <= @error_level
        BEGIN
                


        
                IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 127, 5 ) + " -- MSG: " + "Validate branch exists and is active in Header"
        
        	UPDATE #cmmtvhdr
                SET temp_flag = 0
         
        	UPDATE #cmmtvhdr        
                SET temp_flag = 1
                FROM #cmmtvhdr a, Organization c
                WHERE a.org_id = c.organization_id
                        AND c.active_flag = 1
                
        
                INSERT INTO #ewerror
        	(       module_id,      err_code,       info1,
        		info2,          infoint,        infofloat,
        		flag1,          trx_ctrl_num,   sequence_id,
        		source_ctrl_num,extra
        	)
        	SELECT 7000, 10250,      org_id,
        	        org_id,       user_id,          0.0,
        		1,              trx_ctrl_num,   -1,
        		"",             0        
                FROM #cmmtvhdr 
        	WHERE interbranch_flag = 1
        	     AND temp_flag = 0
        END

END




IF (@batch_proc_flag = 1)
   BEGIN
	IF (SELECT err_type FROM cmedterr WHERE err_code = 10010) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 163, 5 ) + " -- MSG: " + "Validate batch_code exists"
		


	      INSERT #ewerror
		  SELECT 7000,
		  		 10010,
		  		 batch_code,
		  		 "",
				 0,
				 0.0,
				 1,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #cmmtvhdr 
	  	  WHERE batch_code NOT IN (SELECT batch_ctrl_num
								   FROM batchctl)
 	END
   END

IF (SELECT err_type FROM cmedterr WHERE err_code = 10110) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 187, 5 ) + " -- MSG: " + "Check if posted flag is valid"
	


      INSERT #ewerror
	  SELECT 7000,
			 10110,
			 "",
			 "",
			 posted_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr b
  	  WHERE posted_flag != 0
END

IF (SELECT err_type FROM cmedterr WHERE err_code = 10130) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 209, 5 ) + " -- MSG: " + "Check if hold flag is valid"
	


      INSERT #ewerror
	  SELECT 7000,
	  		 10130,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr 
  	  WHERE hold_flag NOT IN (0,1)
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 10120) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 232, 5 ) + " -- MSG: " + "Check if trx is on hold"
	


      INSERT #ewerror
	  SELECT 7000,
			 10120,
			 "",
			 "",
			 hold_flag,
			 0.0,
			 2,	
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr
  	  WHERE hold_flag = 1
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 10020) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 256, 5 ) + " -- MSG: " + "Check if date applied <= 0"
	


      INSERT #ewerror
	  SELECT 7000,
			 10020,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr
  	  WHERE date_applied <= 0
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 10030) <= @error_level
BEGIN
   	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 279, 5 ) + " -- MSG: " + "Check if applied to future period"
	


      INSERT #ewerror
	  SELECT 7000,
			 10030,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr b, cmco c
  	  WHERE b.date_applied > c.period_end_date
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 10040) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 302, 5 ) + " -- MSG: " + "Check if applied to prior period"
	


      INSERT #ewerror
	  SELECT 7000,
			 10040,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr b, glprd c, cmco d
  	  WHERE b.date_applied < c.period_start_date
	  AND c.period_end_date = d.period_end_date
END


IF (SELECT err_type FROM cmedterr WHERE err_code = 10060) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 326, 5 ) + " -- MSG: " + "Check if applied period exists"
	


      UPDATE #cmmtvhdr
      SET flag = 1
	  FROM #cmmtvhdr, glprd c
  	  WHERE #cmmtvhdr.date_applied BETWEEN c.period_start_date AND c.period_end_date


      INSERT #ewerror
	  SELECT 7000,
			 10060,
			 "",
			 "",
			 date_applied,
			 0.0,
			 3,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr
  	  WHERE flag = 0


     UPDATE #cmmtvhdr
     SET flag = 0
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 10050) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 360, 5 ) + " -- MSG: " + "Check if date applied in valid cmco range"
	


      INSERT #ewerror
	  SELECT 7000,
			 10050,
			 "",
			 "",
			 b.date_applied,
			 0.0,
			 3,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr b, cmco c
  	  WHERE abs(b.date_applied - b.date_entered) > c.date_range_verify
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 10080) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 384, 5 ) + " -- MSG: " + "Validate currency_code exists"
	


      INSERT #ewerror
	  SELECT 7000,
			 10080,
			 currency_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr
  	  WHERE currency_code NOT IN (SELECT currency_code FROM glcurr_vw)
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 10090) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 408, 5 ) + " -- MSG: " + "Validate rate_type_home exists"
	


      INSERT #ewerror
	  SELECT 7000,
			 10090,
			 rate_type_home,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr
  	  WHERE rate_type_home NOT IN (SELECT rate_type FROM glrtype_vw)
END



IF (SELECT err_type FROM cmedterr WHERE err_code = 10100) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 432, 5 ) + " -- MSG: " + "Validate rate_type_oper exists"
	


      INSERT #ewerror
	  SELECT 7000,
			 10100,
			 rate_type_oper,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #cmmtvhdr
  	  WHERE rate_type_oper NOT IN (SELECT rate_type FROM glrtype_vw)
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10180) <= @error_level
BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 455, 5 ) + " -- MSG: " + "Check if reference code exists in GL"
      INSERT #ewerror
	  SELECT 7000,
			 10180,
			 reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmmtvhdr b 
	  WHERE b.reference_code NOT IN (SELECT reference_code FROM glref)    
	  AND b.reference_code != ''
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10150) <= @error_level
BEGIN

  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 476, 5 ) + " -- MSG: " + "Check if reference code is required"
      UPDATE #cmmtvhdr
	  SET flag = 1
	  FROM #cmmtvhdr, glrefact b
	  WHERE #cmmtvhdr.cash_acct_code LIKE b.account_mask
	  AND b.reference_flag = 1
	  AND #cmmtvhdr.reference_code = ''


      INSERT #ewerror
	  SELECT 7000,
			 10150,
			 a.cash_acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmmtvhdr a, glrefact b
	  WHERE
		 a.cash_acct_code LIKE b.account_mask
	  AND b.reference_flag = 3
	  AND a.reference_code = ""
	  AND a.flag = 0

	  UPDATE #cmmtvhdr
	  SET flag = 0
	  WHERE flag <> 0
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 511, 5 ) + " -- MSG: " + "Check if reference code is excluded invalid"
	  



      UPDATE #cmmtvhdr
	  SET flag = 1
	  FROM #cmmtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmmtvhdr.cash_acct_code LIKE c.account_mask
	  AND #cmmtvhdr.reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag = 1
	  AND d.reference_type = b.reference_type
	  AND #cmmtvhdr.reference_code != ""

IF (SELECT err_type FROM apedterr WHERE err_code = 10160) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 10160,
			 reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmmtvhdr a
	  WHERE a.flag = 1
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 549, 5 ) + " -- MSG: " + "Check if reference code is not allowed"
	  


      UPDATE #cmmtvhdr
	  SET flag = 2
	  FROM #cmmtvhdr, glrefact b
	  WHERE #cmmtvhdr.cash_acct_code LIKE b.account_mask
	  AND #cmmtvhdr.reference_code != ""
	  AND b.reference_flag IN (2,3)
	  AND #cmmtvhdr.flag = 0

IF (SELECT err_type FROM apedterr WHERE err_code = 10160) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 10160,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmmtvhdr a
	  WHERE a.flag = 0
	  AND a.reference_code != ""
END


	 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 588, 5 ) + " -- MSG: " + "Check if reference code is required or optional and invalid"
	  


      UPDATE #cmmtvhdr
	  SET flag = 3
	  FROM #cmmtvhdr, glref b, glrefact c, glratyp d
	  WHERE #cmmtvhdr.cash_acct_code LIKE c.account_mask
	  AND #cmmtvhdr.reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag IN (2,3)
	  AND d.reference_type = b.reference_type
	  AND #cmmtvhdr.reference_code != ""
	  AND #cmmtvhdr.flag = 2

IF (SELECT err_type FROM apedterr WHERE err_code = 10170) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 10170,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM  #cmmtvhdr a
	  WHERE a.flag = 2
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmthdr1.cpp" + ", line " + STR( 626, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cmmthdr1_sp] TO [public]
GO
