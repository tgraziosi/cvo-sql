SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvehdr1_sp] @error_level smallint, @debug_level smallint = 0
AS
  DECLARE @one_time_vend_code   varchar(12),
		  @intercompany_flag    smallint,
		  @batch_proc_flag		smallint

  DECLARE @ib_flag		INTEGER


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

SELECT @one_time_vend_code = one_time_vend_code,
	   @intercompany_flag = intercompany_flag,
	   @batch_proc_flag = batch_proc_flag
FROM apco  




SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco




UPDATE  #apvovchg
SET     interbranch_flag = 1
FROM 	#apvovchg a, #apvovcdt b 
WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
AND   	a.org_id <> b.org_id
AND      a.company_code = b.rec_company_code --SCR 38369 	




IF @ib_flag = 1 
BEGIN

	




	IF (SELECT err_type FROM apedterr WHERE err_code = 19160) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 79, 5 ) + " -- MSG: " + "Validate a relationship exists for all organizations in an inter-organization trx in apinpchg/apinpcdt"

		





































--REV 2.1
		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	19160, 			a.org_id + ' - ' + b.org_id,
			a.org_id, 		user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	b.sequence_id,
			'', 			0
		FROM 	#apvovchg a
			INNER JOIN #apvovcdt b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.org_id <> b.org_id AND a.company_code = b.rec_company_code	 -- Rev 1.1	
			LEFT JOIN (	SELECT a.trx_ctrl_num 
						FROM 	#apvovchg a
						INNER JOIN #apvovcdt b ON a.trx_ctrl_num = b.trx_ctrl_num
						INNER JOIN OrganizationOrganizationRel oor ON a.org_id = oor.controlling_org_id	AND b.org_id = oor.detail_org_id) TEMP ON a.trx_ctrl_num = TEMP.trx_ctrl_num 
		WHERE 	a.interbranch_flag = 1
		AND TEMP.trx_ctrl_num IS NULL

	END


	



	IF (SELECT err_type FROM apedterr WHERE err_code = 19180) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 151, 5 ) + " -- MSG: " + "Validate organization exists and is active in Header"
























		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	19180, 		org_id,
			org_id, 		user_id, 	0.0,
			1, 			trx_ctrl_num, 	0,
			"", 			0
		FROM 	#apvovchg a
			LEFT JOIN Organization ood ON a.org_id = ood.organization_id AND ood.active_flag = 1
		WHERE ood.organization_id IS NULL

	END

	
	


	IF (((SELECT err_type FROM apedterr WHERE err_code = 19220) <= @error_level) AND (@batch_proc_flag = 1))
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 201, 5 ) + " -- MSG: " + "It can not exists inter-organization voucher and inter-company voucher in the same batch."

		






























 
		DECLARE @intercompany INTEGER
		SET @intercompany = 0

                IF EXISTS (SELECT 1 FROM #apvovchg WHERE intercompany_flag = 1)
                BEGIN

		   SET @intercompany = 1

		END

                IF ( @debug_level > 1 )
		SELECT 'Intercompany Flag  = '+ CONVERT(char, @intercompany,109)
		
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
		FROM 	#apvovchg
		WHERE 	interbranch_flag = 1 and @intercompany = 1
		
		
	END	
	




END


IF (SELECT err_type FROM apedterr WHERE err_code = 10823) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 265, 5 ) + " -- MSG: " + "Validate intercompany flag in apinpchg"
	


	   IF (@intercompany_flag = 0)
	      INSERT #ewerror
		  SELECT 4000,
		   		 10823,
		  		 "",
				 "",
				 intercompany_flag,
				 0.0,
				 2,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apvovchg 
		  WHERE intercompany_flag = 1
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10015) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 288, 5 ) + " -- MSG: " + "Validate doc ctrl num not blank if non-recurring"
	


	      INSERT #ewerror
		  SELECT 4000,
		  		 10015,
				 "",
				 "",
				 0,
				 0.0,
				 0,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apvovchg
	  	  WHERE recurring_flag = 0
		  AND doc_ctrl_num = ""
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10010) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/apvehdr1.sp' + ', line ' + STR( 95, 5 ) + ' -- MSG: ' + 'Validate doc ctrl num doesnt exist for same vendor in apinpchg'
	
	 INSERT #ewerror
		 SELECT 4000,


				 10010,
				 b.doc_ctrl_num,
				 '',
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 '',
				 0
		 FROM #apvovchg b, apinpchg_all c
	 	 WHERE c.trx_type = 4091
		 AND b.doc_ctrl_num = c.doc_ctrl_num
		 AND b.vendor_code = c.vendor_code
		 AND b.vendor_code != @one_time_vend_code
		 AND b.trx_ctrl_num <> c.trx_ctrl_num
		 AND b.recurring_flag <>1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/apvehdr1.sp' + ', line ' + STR( 118, 5 ) + ' -- MSG: ' + 'Validate doc ctrl num doesnt exist for same vendor in apvohdr'
	
	 INSERT #ewerror
		 SELECT 4000,


				 10010,
				 '',
				 b.doc_ctrl_num,
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 '',
				 0
		 FROM #apvovchg b, apvohdr_all c
	 	 WHERE b.doc_ctrl_num = c.doc_ctrl_num
		 AND b.vendor_code = c.vendor_code
		 AND b.recurring_flag <> 1

END


IF (SELECT err_type FROM apedterr WHERE err_code = 10011) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/apvehdr1.sp' + ', line ' + STR( 95, 5 ) + ' -- MSG: ' + 'Validate doc ctrl num doesnt exist for same vendor in apinpchg'
	BEGIN 










































--rev 2.1 
	 INSERT #ewerror
		 SELECT 4000,
				 10011,
				 '',
				 b.doc_ctrl_num,
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 '',
				 0
		 FROM #apvovchg b
			INNER JOIN apinpchg_all c ON b.doc_ctrl_num = c.doc_ctrl_num AND b.vendor_code = c.vendor_code AND b.trx_ctrl_num <> c.trx_ctrl_num
	 	 WHERE c.trx_type = 4091
		 AND b.vendor_code != @one_time_vend_code	 
		 AND b.recurring_flag = 1
	
		 UNION ALL
	
		 SELECT DISTINCT 4000,
				 10011,
				 '',
				 b.doc_ctrl_num,
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 '',
				 0
		 FROM #apvovchg b
			INNER JOIN apvohdr_all c  ON b.doc_ctrl_num = c.doc_ctrl_num AND b.vendor_code = c.vendor_code
	 	 WHERE b.recurring_flag = 1

	END

--REV 2.1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10020) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 451, 5 ) + " -- MSG: " + "Validate apply_to_num exists in apvohdr or is blank"
	


	
















	      INSERT #ewerror
		  SELECT 4000,
		  		 10020,
				 b.apply_to_num,
				 '',
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 '',
				 0
			from #apvovchg b
				left join apvohdr apvo on b.apply_to_num = apvo.trx_ctrl_num
			where b.apply_to_num != '' and apvo.trx_ctrl_num is null


END

  
IF (SELECT err_type FROM apedterr WHERE err_code = 10030) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 494, 5 ) + " -- MSG: " + "Validate user_trx_type_code exists in apusrtyp or is blank"
	


	      INSERT #ewerror
		  SELECT 4000,
				 10030,
				 a.user_trx_type_code,
				 "",
				 0,
				 0.0,
				 1,
				 a.trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #apvovchg a
			LEFT JOIN apusrtyp b on a.user_trx_type_code = b.user_trx_type_code
	  	  WHERE b.user_trx_type_code != ""
		  AND b.user_trx_type_code IS NULL
END


IF (@batch_proc_flag = 1)
   BEGIN
	IF (SELECT err_type FROM apedterr WHERE err_code = 10040) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 521, 5 ) + " -- MSG: " + "Validate batch_code exists"
		


		

















	      INSERT #ewerror
		  SELECT 4000,
		  		 10040,
		  		 b.batch_code,
		  		 '',
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 '',
				 0
		FROM #apvovchg b
			left join batchctl bat on b.batch_code = bat.batch_ctrl_num
		where bat.batch_ctrl_num is null

 	END
   END


IF (SELECT err_type FROM apedterr WHERE err_code = 10210) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 565, 5 ) + " -- MSG: " + "Validate posting_code exists"
	


	
















      INSERT #ewerror
	  SELECT 4000,
	  		 10210,
	  		 b.posting_code,
	  		 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	from #apvovchg b
		left join apaccts ap on b.posting_code = ap.posting_code
	where ap.posting_code is null

END


IF (SELECT err_type FROM apedterr WHERE err_code = 10220) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 607, 5 ) + " -- MSG: " + "Validate vendor_code exists"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 10220,
	  		 b.vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
		LEFT JOIN apvend a ON b.vendor_code = a.vendor_code
  	  WHERE a.vendor_code IS NULL

END


IF (SELECT err_type FROM apedterr WHERE err_code = 10230) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 632, 5 ) + " -- MSG: " + "Validate vendor_code is active"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 10230,
	  		 b.vendor_code,
	  		 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, apmaster_all c (nolock)
  	  WHERE b.vendor_code = c.vendor_code
	  AND c.status_type != 5
	  AND c.address_type = 0

END 


IF (SELECT err_type FROM apedterr WHERE err_code = 10232) <= @error_level
BEGIN
	  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 659, 5 ) + " -- MSG: " + "Validate if vendor_code is one-time flag is set"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 10232,
	  		 "",
			 "",
			 one_time_vend_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE vendor_code = @one_time_vend_code
	  AND one_time_vend_flag = 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10234) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 683, 5 ) + " -- MSG: " + "Validate if vendor_code is not one-time and flag is set"
	


      INSERT #ewerror
	  SELECT 4000,
			 10234,
	  		 "",
			 "",
			 one_time_vend_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
  	  WHERE vendor_code != @one_time_vend_code
	  AND one_time_vend_flag = 1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10240) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 707, 5 ) + " -- MSG: " + "Validate if pay_to_code is valid or blank"
	


      INSERT #ewerror
	  SELECT 4000,
	         10240,
	         b.pay_to_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
		LEFT JOIN appayto c ON c.vendor_code = b.vendor_code AND c.pay_to_code = b.pay_to_code
	  WHERE b.pay_to_code != ""
	  AND c.pay_to_code IS NULL
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10250) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 732, 5 ) + " -- MSG: " + "Validate pay_to_code is active or blank"
	


      INSERT #ewerror
	  SELECT 4000,
	  		 10250,
	  		 b.pay_to_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, appayto c
  	  WHERE b.vendor_code = c.vendor_code
	  AND b.pay_to_code = c.pay_to_code
	  AND c.status_type != 5
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10260) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 756, 5 ) + " -- MSG: " + "Check if pay_to_code is vendors default"
	


	



















      INSERT #ewerror
	  SELECT 4000,
			 10260,
			 b.pay_to_code,
	  		 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM apvohdr_all b
		INNER JOIN apmaster_all c (nolock) ON b.vendor_code = c.vendor_code AND b.pay_to_code != c.pay_to_code 
		INNER JOIN apmaster_all d(nolock) ON b.vendor_code = d.vendor_code AND b.pay_to_code = d.pay_to_code
  	  WHERE c.address_type = 0
	  AND d.address_type = 1
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10280) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 801, 5 ) + " -- MSG: " + "Validate if branch_code is valid or blank"
	


      INSERT #ewerror
	  SELECT 4000,
			 10280,
			 a.branch_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg a
		LEFT JOIN apbranch b ON a.branch_code = b.branch_code 
  	  WHERE a.branch_code != ""
	  AND b.branch_code IS NULL
END
	  						 

IF (SELECT err_type FROM apedterr WHERE err_code = 10290) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 826, 5 ) + " -- MSG: " + "Check if branch_code is vendors default"
	


	

















      INSERT #ewerror
	  SELECT 4000,
		     10290,
			 b.branch_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apvovchg b
		INNER JOIN apmaster_all c (nolock) ON b.vendor_code = c.vendor_code AND b.branch_code != c.branch_code
		INNER JOIN apbranch d ON b.branch_code = d.branch_code
  	  WHERE c.address_type = 0

END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 868, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvehdr1_sp] TO [public]
GO
