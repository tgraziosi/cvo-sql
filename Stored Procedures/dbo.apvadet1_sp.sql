SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvadet1_sp] @error_level smallint, @debug_level smallint = 0
AS
	DECLARE @ib_flag INTEGER, @ib_segment int, @where_added varchar(600), @ib_offset int, @ib_length int
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 34, 5 ) + " -- ENTRY: "

SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag, @ib_offset = ib_offset,	@ib_length = ib_length,	@ib_segment = ib_segment
FROM 	glco




IF @ib_flag = 1 
BEGIN
	


	IF (SELECT err_type FROM apedterr WHERE err_code = 31250) <= @error_level
  	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 50, 5 ) + " -- MSG: " + "Validate if account mapping exists"
		


























		
		

		
		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 4000,	31250,		a.gl_exp_acct,
			'',			0,		0.0,
			1,			a.trx_ctrl_num,	a.sequence_id,
			'',			0
		FROM 	#apvavcdt a
			INNER JOIN #apvavchg b ON a.trx_ctrl_num = b.trx_ctrl_num ANd a.trx_type = b.trx_type AND  a.org_id <> b.org_id AND a.new_rec_company_code = b.company_code  	 -- Rev 1.1	
			LEFT JOIN (	SELECT a.trx_ctrl_num 
						FROM 	#apvavchg a
							INNER JOIN #apvavcdt b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.trx_type = b.trx_type
							INNER JOIN OrganizationOrganizationDef ood ON b.org_id = ood.detail_org_id AND	b.gl_exp_acct LIKE ood.account_mask
						WHERE 	a.org_id = ood.controlling_org_id) TEMP ON a.trx_ctrl_num = TEMP.trx_ctrl_num
		WHERE 	b.interbranch_flag = 1
		AND TEMP.trx_ctrl_num IS NULL		--Rev 1.2
				
	END
	

	


	IF (SELECT err_type FROM apedterr WHERE err_code = 31270) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 113, 5 ) + " -- MSG: " + "Validate organization exists and is active in Detail"
		



























		



		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	31270, 		b.org_id,
			b.org_id, 		0, 		0.0,
			1, 			b.trx_ctrl_num, 	b.sequence_id,
			"", 			0
		FROM 	#apvavcdt b
			INNER JOIN #apvavchg a ON b.trx_ctrl_num = a.trx_ctrl_num AND b.trx_type = a.trx_type AND b.new_rec_company_code = a.company_code -- Rev 1.1	
			LEFT JOIN Organization o ON b.org_id = o.organization_id AND o.active_flag = 1
		WHERE o.organization_id IS NULL		--Rev 1.2
  	END

	



	IF (SELECT err_type FROM apedterr WHERE err_code = 31280) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \apinpcdt"

		


		UPDATE 	#apvavcdt
	        SET 	temp_flag = 0

		








		
		



		SELECT @where_added = 'o.branch_account_number = SUBSTRING(seg'+cast(@ib_segment as varchar(2)) +'_code,'+ cast(@ib_offset as varchar(2))+','+cast(@ib_length as varchar(2))+')'
		
				
		EXEC ('UPDATE #apvavcdt SET temp_flag = 1 FROM #apvavcdt a , glchart c, Organization_all o ' +
		' WHERE a.new_gl_exp_acct = c.account_code ' +
		' AND '+ @where_added +
		' AND a.org_id = o.organization_id')		--Rev 1.2
		
		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	31280, 			a.gl_exp_acct,
			a.org_id, 		0, 		0.0,
			0, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#apvavcdt a, #apvavchg b		 	--Rev 1.1
		WHERE 	a.temp_flag = 0
		AND	a.trx_ctrl_num = b.trx_ctrl_num			--Rev 1.1
		AND	a.trx_type = b.trx_type			 	--Rev 1.1	
		AND     b.company_code = a.new_rec_company_code		--Rev 1.1
	END
	
END

ELSE
BEGIN
	


	IF (SELECT err_type FROM apedterr WHERE err_code = 31290) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same apinpchg/apinpcdt"

		









		UPDATE 	#apvavcdt
	        SET 	temp_flag = 1				--Rev 1.2
		FROM 	#apvavcdt a, #apvavchg b		--Rev 1.2
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num		--Rev 1.2
		ANd	a.trx_type = b.trx_type			--Rev 1.2
		AND 	a.org_id = b.org_id			--Rev 1.2

		




		
















		


		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 			31290, 			b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#apvavcdt a
			INNER JOIN #apvavchg b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.rec_company_code = b.company_code 	 -- Rev 1.1	
			LEFT JOIN #apvavchg c ON a.trx_ctrl_num = c.trx_ctrl_num ANd a.trx_type = c.trx_type AND a.org_id = c.org_id
		WHERE a.temp_flag = 0
		
	END
END


IF (SELECT err_type FROM apedterr WHERE err_code = 30840) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 300, 5 ) + " -- MSG: " + "Check if any sequence_id is less than 1"
	


      INSERT #ewerror
	  SELECT 4000,
			 30840,
			 "",
			 "",
			 sequence_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvavcdt 
  	  WHERE sequence_id < 1
END

IF ((SELECT intercompany_flag FROM apco) = 1)
   BEGIN

    IF (SELECT err_type FROM apedterr WHERE err_code = 31071) <= @error_level
      BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 325, 5 ) + " -- MSG: " + "Check if recipient company code exists"
			


      		INSERT #ewerror
			SELECT 4000,
				   31071,
				   rec_company_code,
				   "",
				   0,
				   0.0,
				   1,
				   trx_ctrl_num,
				   sequence_id,
				   "",
				   0
			  FROM #apvavcdt 
		  	  WHERE rec_company_code NOT IN (SELECT company_code FROM glcomp_vw)
	   END


   IF (SELECT err_type FROM apedterr WHERE err_code = 31068) <= @error_level
      BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 348, 5 ) + " -- MSG: " + "Verify intercompany definition"
		


      INSERT #ewerror
	  SELECT 4000,
			 31068,
			 b.rec_company_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
		  FROM #apvavcdt b, #apvavchg c
	  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
		  AND c.company_code != b.rec_company_code
		  AND NOT EXISTS (SELECT *
		  	  			  FROM glcoco_vw d
		  	  			  WHERE d.rec_code = b.rec_company_code
			  			  AND d.org_code = c.company_code 
			  			  AND d.rec_code = b.rec_company_code)

	   END

   IF (SELECT err_type FROM apedterr WHERE err_code = 31041) <= @error_level
       BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 377, 5 ) + " -- MSG: " + "Verify intercompany definition for the expense account"
			



			  UPDATE #apvavcdt
			  SET flag = 1
			  FROM #apvavcdt, #apvavchg b
			  WHERE #apvavcdt.trx_ctrl_num = b.trx_ctrl_num
			  AND #apvavcdt.rec_company_code = b.company_code
		
		
			  UPDATE #apvavcdt
			  SET flag = 1
			  FROM #apvavcdt,  #apvavchg c, glcocodt_vw d
		  	  WHERE #apvavcdt.trx_ctrl_num = c.trx_ctrl_num
			  AND c.company_code != #apvavcdt.rec_company_code
			  AND d.rec_code = #apvavcdt.rec_company_code
			  AND d.org_code = c.company_code 
			  AND #apvavcdt.gl_exp_acct LIKE d.account_mask


      INSERT #ewerror
	  SELECT 4000,
			 31041,
			 gl_exp_acct,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
 	  FROM #apvavcdt 
   	  WHERE flag = 0		


	END
  END

ELSE

  BEGIN

	IF (SELECT err_type FROM apedterr WHERE err_code = 31067) <= @error_level
       BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 424, 5 ) + " -- MSG: " + "Check if company codes are same in header and detail"
			


          INSERT #ewerror
	      SELECT 4000,
			 31067,
			 b.rec_company_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
     	  FROM #apvavcdt b, #apvavchg c
		  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
			  AND b.rec_company_code != c.company_code
	   END

  END





IF (SELECT err_type FROM apedterr WHERE err_code = 31072) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 453, 5 ) + " -- MSG: " + "Check if company_id exists"
	


      INSERT #ewerror
	  SELECT 4000,
			 31072,
			 "",
			 "",
			 company_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvavcdt b
  	  WHERE NOT EXISTS (SELECT c.company_id FROM glcomp_vw c 
	                  WHERE c.company_code = b.rec_company_code
	                  AND c.company_id = b.company_id)
END






	 



	 INSERT #apveacct
	 SELECT d.db_name,
	 		b.trx_ctrl_num,
			b.sequence_id,
			1,
			b.new_gl_exp_acct,
			c.date_applied,
			b.new_reference_code,
			0,
			b.org_id
	 FROM   #apvavcdt b, #apvavchg c, glcomp_vw d
	 WHERE b.trx_ctrl_num = c.trx_ctrl_num
	 AND b.new_rec_company_code = d.company_code






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvadet1.cpp" + ", line " + STR( 503, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvadet1_sp] TO [public]
GO
