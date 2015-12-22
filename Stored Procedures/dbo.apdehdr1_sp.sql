SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[apdehdr1_sp] @error_level smallint, @debug_level smallint = 0
AS
  DECLARE @intercompany_flag    smallint,
		  @batch_proc_flag		smallint
  DECLARE @ib_flag INTEGER

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "
SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco


SELECT @intercompany_flag = intercompany_flag,
	   @batch_proc_flag = batch_proc_flag
FROM apco  



UPDATE  #apdmvchg
SET     interbranch_flag = 1
FROM 	#apdmvchg a, #apdmvcdt b 
WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
AND     a.company_code = b.rec_company_code 
AND   	a.org_id <> b.org_id




IF @ib_flag = 1 
BEGIN	
	



	IF (SELECT err_type FROM apedterr WHERE err_code = 21170) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 64, 5 ) + " -- MSG: " + "Validate a relationship exists for all organizations in an inter-organization trx in apinpchg/apinpcdt"

		





























		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	21170, 			a.org_id + ' - ' + b.org_id,
			a.trx_ctrl_num,		user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	b.sequence_id,
			'', 			0
		FROM 	#apdmvchg a
			INNER JOIN #apdmvcdt b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.org_id <> b.org_id AND a.company_code = b.rec_company_code	 -- Rev 1.1	
			LEFT JOIN (	SELECT a.trx_ctrl_num 
						FROM 	#apdmvchg a
						INNER JOIN #apdmvcdt b ON a.trx_ctrl_num = b.trx_ctrl_num
						INNER JOIN OrganizationOrganizationRel oor ON a.org_id = oor.controlling_org_id	AND b.org_id = oor.detail_org_id) TEMP ON a.trx_ctrl_num = TEMP.trx_ctrl_num 
		WHERE 	a.interbranch_flag = 1
		AND TEMP.trx_ctrl_num IS NULL


	END


	



	IF (SELECT err_type FROM apedterr WHERE err_code = 21190) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 128, 5 ) + " -- MSG: " + "Validate organization exists and is active in Header"
		






















		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	21190, 		org_id,
			org_id, 		user_id, 	0.0,
			1, 			trx_ctrl_num, 	0,
			"", 			0
		FROM 	#apdmvchg a
			LEFT JOIN Organization ood ON a.org_id = ood.organization_id AND ood.active_flag = 1
		WHERE ood.organization_id IS NULL

	END

	
	


	IF (((SELECT err_type FROM apedterr WHERE err_code = 19220) <= @error_level) AND (@batch_proc_flag = 1))
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 177, 5 ) + " -- MSG: " + "It can not exists inter-organization voucher and inter-company voucher in the same batch."

		
































		/*	
		DECLARE @intercompany INTEGER
		SET @intercompany = 0
		SET @intercompany = (SELECT 1 FROM #apdmvchg WHERE intercompany_flag = 1)
		*/

		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	19220, 		org_id,
			org_id, 		user_id, 	0.0,
			1, 			trx_ctrl_num, 	0,
			"", 			0
		FROM 	#apdmvchg
		WHERE 	interbranch_flag = 1 and intercompany_flag = 1		


	END	
	




END


IF (SELECT err_type FROM apedterr WHERE err_code = 20823) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 242, 5 ) + " -- MSG: " + "Validate intercompany flag in apinpchg"
	


	   IF (@intercompany_flag = 0)
	      INSERT #ewerror
		  SELECT 4000,
		   		 20823,
		  		 "",
				 "",
				 intercompany_flag,
				 0.0,
				 2,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apdmvchg 
		  WHERE intercompany_flag = 1
END

IF (SELECT err_type FROM apedterr WHERE err_code = 20015) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 265, 5 ) + " -- MSG: " + "Validate doc ctrl num not blank"
	


	      INSERT #ewerror
		  SELECT 4000,
		  		 20015,
				 "",
				 "",
				 0,
				 0.0,
				 0,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apdmvchg
	  	  WHERE doc_ctrl_num = ""
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20020) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 289, 5 ) + " -- MSG: " + "Validate apply_to_num exists in apvohdr or is blank"
	


	      INSERT #ewerror
		  SELECT 4000,
		  		 20020,
				 a.apply_to_num,
				 "",
				 0,
				 0.0,
				 1,
				 a.trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apdmvchg a
			LEFT JOIN apvohdr c ON a.apply_to_num = c.trx_ctrl_num 
	  	  WHERE a.apply_to_num != ""
			AND c.trx_ctrl_num IS NULL
		  

END

  
IF (SELECT err_type FROM apedterr WHERE err_code = 20030) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 316, 5 ) + " -- MSG: " + "Validate user_trx_type_code exists in apusrtyp or is blank"
	


	      INSERT #ewerror
		  SELECT 4000,
				 20030,
				 a.user_trx_type_code,
				 "",
				 0,
				 0.0,
				 1,
				 a.trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apdmvchg a
			LEFT JOIN apusrtyp c on a.user_trx_type_code = c.user_trx_type_code
	  	  WHERE a.user_trx_type_code != ""
			AND c.user_trx_type_code IS NULL
END


IF (@batch_proc_flag = 1)
   BEGIN
	IF (SELECT err_type FROM apedterr WHERE err_code = 20040) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 343, 5 ) + " -- MSG: " + "Validate batch_code exists"
		


	      INSERT #ewerror
		  SELECT 4000,
		  		 20040,
		  		 a.batch_code,
		  		 "",
				 0,
				 0.0,
				 1,
				 a.trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apdmvchg a
			LEFT JOIN batchctl c ON a.batch_code = c.batch_ctrl_num
	  	  WHERE c.batch_ctrl_num IS NULL
 	END
   END


IF (SELECT err_type FROM apedterr WHERE err_code = 20210) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 368, 5 ) + " -- MSG: " + "Validate posting_code exists"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 20210,
	  		 b.posting_code,
	  		 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
		LEFT JOIN apaccts c ON b.posting_code = c.posting_code
  	  WHERE c.posting_code IS NULL
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20220) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 392, 5 ) + " -- MSG: " + "Validate vendor_code exists"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 20220,
	  		 b.vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
		LEFT JOIN apvend a ON b.vendor_code = a.vendor_code
  	  WHERE a.vendor_code IS NULL


END


IF (SELECT err_type FROM apedterr WHERE err_code = 20230) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 418, 5 ) + " -- MSG: " + "Validate vendor_code is active"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 20230,
	  		 b.vendor_code,
	  		 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, apvend c
  	  WHERE b.vendor_code = c.vendor_code
	  AND c.status_type != 5
END 



IF (SELECT err_type FROM apedterr WHERE err_code = 20240) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 443, 5 ) + " -- MSG: " + "Validate if pay_to_code is valid or blank"
	






















      INSERT #ewerror
	  SELECT 4000,
	         20240,
	         b.pay_to_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
		LEFT JOIN apvnd_vw c ON b.vendor_code = c.vendor_code AND b.pay_to_code = c.pay_to_code 
	  WHERE b.pay_to_code != "" AND c.vendor_code IS NULL


END


IF (SELECT err_type FROM apedterr WHERE err_code = 20250) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 489, 5 ) + " -- MSG: " + "Validate pay_to_code is active or blank"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 20250,
	  		 b.pay_to_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, apvnd_vw c
  	  WHERE b.vendor_code = c.vendor_code
	  AND b.pay_to_code = c.pay_to_code
	  AND c.status_type != 5

END

IF (SELECT err_type FROM apedterr WHERE err_code = 20260) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 514, 5 ) + " -- MSG: " + "Check if pay_to_code is vendors default"
	




















	 INSERT #ewerror
	  SELECT 4000,
			 20260,
			 b.pay_to_code,
	  		 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
		INNER JOIN apmaster_all c (nolock) ON b.vendor_code = c.vendor_code AND b.pay_to_code != c.pay_to_code 
		INNER JOIN apmaster_all d(nolock) ON b.vendor_code = d.vendor_code AND b.pay_to_code = d.pay_to_code
  	  WHERE c.address_type = 0
	  AND d.address_type = 1



END

IF (SELECT err_type FROM apedterr WHERE err_code = 20280) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 560, 5 ) + " -- MSG: " + "Validate if branch_code is valid or blank"
	


      















	
	INSERT #ewerror
	  SELECT 4000,
			 20280,
			 a.branch_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg a
		LEFT JOIN apbranch b ON a.branch_code = b.branch_code 
  	  WHERE a.branch_code != ""
	  AND b.branch_code IS NULL


END
	  						 

IF (SELECT err_type FROM apedterr WHERE err_code = 20290) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 604, 5 ) + " -- MSG: " + "Check if branch_code is vendors default"
	


















	
	INSERT #ewerror
	  SELECT 4000,
		     20290,
			 b.branch_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
		INNER JOIN apmaster_all c (nolock) ON b.vendor_code = c.vendor_code AND b.branch_code != c.branch_code
		INNER JOIN apbranch d ON b.branch_code = d.branch_code
  	  WHERE c.address_type = 0


END

IF (SELECT err_type FROM apedterr WHERE err_code = 20300) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 647, 5 ) + " -- MSG: " + "Validate if class_code is valid or blank"
	


      INSERT #ewerror
	  SELECT 4000,
			 20300,
			 class_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg 
  	  WHERE class_code NOT IN (SELECT class_code FROM apclass)
	  AND class_code != ""
END
	  						 

IF (SELECT err_type FROM apedterr WHERE err_code = 20310) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 671, 5 ) + " -- MSG: " + "Check if class_code is vendors default"
	


      INSERT #ewerror
	  SELECT 4000,
			 20310,
			 b.class_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, apvend c, apclass d
  	  WHERE b.vendor_code = c.vendor_code
	  AND b.class_code = d.class_code
	  AND c.vend_class_code != b.class_code
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20390) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 697, 5 ) + " -- MSG: " + "Check if comment code is not valid and is not blank"
	


      INSERT #ewerror
	  SELECT 4000,
			 20390,
			 b.comment_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b
		LEFT JOIN apcommnt c ON b.comment_code = c.comment_code 
  	  WHERE b.comment_code != "" AND c.comment_code IS NULL
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20380) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 721, 5 ) + " -- MSG: " + "Check if comment code is not the default"
	


      INSERT #ewerror
	  SELECT 4000,
			 20380,
			 b.comment_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apdmvchg b, apcommnt c, apvend d
  	  WHERE b.comment_code = c.comment_code
	  AND b.vendor_code = d.vendor_code
	  AND b.comment_code != d.comment_code
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdehdr1.cpp" + ", line " + STR( 744, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apdehdr1_sp] TO [public]
GO
