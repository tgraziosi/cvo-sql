SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[apvedet1_sp] @error_level smallint, @debug_level smallint = 0
AS

  DECLARE @ib_flag		INTEGER
  
  DECLARE	@org_id varchar(30), @ib_segment int, @ib_offset int,@ib_length int, 
			@where_added varchar(600)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 52, 5 ) + " -- ENTRY: "




SELECT 	@ib_flag = 0

SELECT 	@ib_flag = ib_flag, @ib_offset = ib_offset,	@ib_length = ib_length,	@ib_segment = ib_segment
FROM 	glco




IF @ib_flag = 1 
BEGIN
	



	IF (SELECT err_type FROM apedterr WHERE err_code = 19170) <= @error_level
  	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 73, 5 ) + " -- MSG: " + "Validate if account mapping exists"
		










































--Rev 2.1

	
		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 4000,	19170,		a.gl_exp_acct,
			'',			0,		0.0,
			1,			a.trx_ctrl_num,	a.sequence_id,
			'',			0
		FROM 	#apvovcdt a
			INNER JOIN #apvovchg b ON a.trx_ctrl_num = b.trx_ctrl_num ANd a.trx_type = b.trx_type AND  a.org_id <> b.org_id AND a.rec_company_code = b.company_code  	 -- Rev 1.1	
			LEFT JOIN (	SELECT a.trx_ctrl_num 
						FROM 	#apvovchg a
							INNER JOIN #apvovcdt b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.trx_type = b.trx_type
							INNER JOIN OrganizationOrganizationDef ood ON b.org_id = ood.detail_org_id AND	b.gl_exp_acct LIKE ood.account_mask
						WHERE 	a.org_id = ood.controlling_org_id) TEMP ON a.trx_ctrl_num = TEMP.trx_ctrl_num
		WHERE 	b.interbranch_flag = 1
		AND TEMP.trx_ctrl_num IS NULL


	END
	

	



	IF (SELECT err_type FROM apedterr WHERE err_code = 19190) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 153, 5 ) + " -- MSG: " + "Validate organization exists and is active in Detail"
		






































--Rev 2.0		

		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	19190, 		b.org_id,
			b.org_id, 		0, 		0.0,
			1, 			b.trx_ctrl_num, 	b.sequence_id,
			"", 			0
		FROM 	#apvovcdt b
			INNER JOIN #apvovchg a ON b.trx_ctrl_num = a.trx_ctrl_num AND b.trx_type = a.trx_type AND b.rec_company_code = a.company_code -- Rev 1.1	
			LEFT JOIN Organization o ON b.org_id = o.organization_id AND o.active_flag = 1
		WHERE o.organization_id IS NULL
		
  	END

	



	IF (SELECT err_type FROM apedterr WHERE err_code = 19200) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \apinpcdt"

		


		UPDATE 	#apvovcdt
	        SET 	temp_flag = 0

		



		
		SELECT @where_added = 'o.branch_account_number = SUBSTRING(seg'+cast(@ib_segment as varchar(2)) +'_code,'+ cast(@ib_offset as varchar(2))+','+cast(@ib_length as varchar(2))+')'

		EXEC ('UPDATE #apvovcdt SET temp_flag = 1 FROM #apvovcdt a , glchart c, Organization_all o ' +
		' WHERE a.gl_exp_acct = c.account_code ' +
		' AND '+ @where_added +
		' AND a.org_id = o.organization_id')
		

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 			19200, 			a.gl_exp_acct,
			a.org_id, 		0, 		0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#apvovcdt a, #apvovchg b
		WHERE 	a.temp_flag = 0 
		AND	a.trx_ctrl_num = b.trx_ctrl_num		 -- Rev 1.1	
		AND	a.trx_type = b.trx_type			 -- Rev 1.1	
		AND     b.company_code = a.rec_company_code	 -- Rev 1.1	
	END

	
END

ELSE
BEGIN
	


	IF (SELECT err_type FROM apedterr WHERE err_code = 19210) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same apinpchg/apinpcdt"

		




































--Rev 2.1

		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 			19210, 			b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 		0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#apvovcdt a
			INNER JOIN #apvovchg b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.rec_company_code = b.company_code 	 -- Rev 1.1	
			LEFT JOIN #apvovchg c ON a.trx_ctrl_num = c.trx_ctrl_num ANd a.trx_type = c.trx_type AND a.org_id = c.org_id
		WHERE c.org_id IS NULL
	
	END
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10840) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 339, 5 ) + " -- MSG: " + "Check if any sequence_id is less than 1"
	


      INSERT #ewerror
	  SELECT 4000,
			 10840,
			 "",
			 "",
			 sequence_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE sequence_id < 1
END

IF ((SELECT intercompany_flag FROM apco) = 1)
   BEGIN

    IF (SELECT err_type FROM apedterr WHERE err_code = 11071) <= @error_level
      BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 364, 5 ) + " -- MSG: " + "Check if recipient company code exists"
			


      		INSERT #ewerror
			SELECT 4000,
				   11071,
				   rec_company_code,
				   "",
				   0,
				   0.0,
				   1,
				   trx_ctrl_num,
				   sequence_id,
				   "",
				   0
			  FROM #apvovcdt 
		  	  WHERE rec_company_code NOT IN (SELECT company_code FROM glcomp_vw)
	   END


   IF (SELECT err_type FROM apedterr WHERE err_code = 11068) <= @error_level
      BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 387, 5 ) + " -- MSG: " + "Verify intercompany definition"
		


      INSERT #ewerror
	  SELECT 4000,
			 11068,
			 b.rec_company_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
		  FROM #apvovcdt b, #apvovchg c
	  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
		  AND c.company_code != b.rec_company_code
		  AND NOT EXISTS (SELECT 1
		  	  			  FROM glcoco_vw d
		  	  			  WHERE d.rec_code = b.rec_company_code
			  			  AND d.org_code = c.company_code 
			  			  AND d.rec_code = b.rec_company_code)

	   END

   IF (SELECT err_type FROM apedterr WHERE err_code = 11041) <= @error_level
       BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 416, 5 ) + " -- MSG: " + "Verify intercompany definition for the expense account"
			




			  UPDATE #apvovcdt
			  SET flag = 1
			  FROM #apvovcdt, #apvovchg b
			  WHERE #apvovcdt.trx_ctrl_num = b.trx_ctrl_num
			  AND #apvovcdt.rec_company_code = b.company_code

			  UPDATE #apvovcdt
			  SET flag = 1
			  FROM #apvovcdt,  #apvovchg c, glcocodt_vw d
		  	  WHERE #apvovcdt.trx_ctrl_num = c.trx_ctrl_num
			  AND c.company_code != #apvovcdt.rec_company_code
			  AND d.rec_code = #apvovcdt.rec_company_code
			  AND d.org_code = c.company_code 
			  AND #apvovcdt.gl_exp_acct LIKE d.account_mask
			  AND #apvovcdt.flag = 0

		      INSERT #ewerror
			  SELECT 4000,
					 11041,
					 gl_exp_acct,
					 "",
					 0,
					 0.0,
					 1,
					 trx_ctrl_num,
					 sequence_id,
					 "",
					 0
		 	  FROM #apvovcdt 
		   	  WHERE flag = 0	

	END
  END

ELSE

  BEGIN

	IF (SELECT err_type FROM apedterr WHERE err_code = 11067) <= @error_level
       BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 462, 5 ) + " -- MSG: " + "Check if company codes are same in header and detail"
			


          INSERT #ewerror
	      SELECT 4000,
			 11067,
			 b.rec_company_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
     	  FROM #apvovcdt b, #apvovchg c
		  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
			  AND b.rec_company_code != c.company_code
	   END

  END





IF (SELECT err_type FROM apedterr WHERE err_code = 11072) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 491, 5 ) + " -- MSG: " + "Check if company_id exists"
	


      INSERT #ewerror
	  SELECT 4000,
			 11072,
			 "",
			 "",
			 b.company_id,
			 0.0,
			 2,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #apvovcdt b
		LEFT JOIN glcomp_vw c ON b.rec_company_code = c.company_code AND b.company_id = c.company_id 
  	  WHERE c.company_id IS NULL
END




IF (SELECT err_type FROM apedterr WHERE err_code = 10880) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 517, 5 ) + " -- MSG: " + "Check if qty_ordered is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 10880,
			 "",
			 "",
			 0,
			 qty_ordered,
			 5,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE ((qty_ordered) < (0.0) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10900) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 541, 5 ) + " -- MSG: " + "Check if qty_received is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 10900,
			 "",
			 "",
			 0,
			 qty_received,
			 5,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE ((qty_received) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10890) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 564, 5 ) + " -- MSG: " + "Check if qty_received > qty_ordered"
	


      INSERT #ewerror
	  SELECT 4000,
			 10890,
			 "",
			 "",
			 0,
			 qty_received,
			 5,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt b
  	  WHERE ((qty_received) > (qty_ordered) + 0.0000001) 
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10910) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 587, 5 ) + " -- MSG: " + "Check if approval code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10910,
			 approval_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",				 
			 0
	  FROM #apvovcdt 
  	  WHERE approval_code NOT IN (SELECT approval_code FROM apapr)
	  AND approval_code != ""
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10920) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 612, 5 ) + " -- MSG: " + "Check if tax code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10920,
			 tax_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apvovcdt 
  	  WHERE tax_code NOT IN (SELECT tax_code FROM aptax)
	  AND tax_code != ""
END

IF (SELECT err_type FROM apedterr WHERE err_code = -10920) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 635, 5 ) + " -- MSG: " + "Check if tax code is valid for tax connect service"
	









		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 4000,  	-10920,
			d.tax_code,			'',
			0,				0.0,
			1,			d.trx_ctrl_num,
			d.sequence_id,			'',
			0
		FROM #apvovchg c 
			join artax tax (nolock) on (c.tax_code = tax.tax_code)
			join #apvovcdt d on (c.trx_ctrl_num = d.trx_ctrl_num AND c.trx_type = d.trx_type)
			join artax td (nolock) on (d.tax_code = td.tax_code)
	  	WHERE tax.tax_connect_flag != td.tax_connect_flag
		
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10934) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 672, 5 ) + " -- MSG: " + "Check if 1099 code is entered but not 1099 vendor"
	










































      INSERT #ewerror
	  SELECT 4000,
			 10934,
			 b.code_1099,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0 
	  FROM #apvovcdt b
		INNER JOIN #apvovchg c ON b.trx_ctrl_num = c.trx_ctrl_num
		INNER JOIN apvend d ON c.vendor_code = d.vendor_code
  	  WHERE c.pay_to_code = ""
	  AND d.flag_1099 = 0
	  AND b.code_1099 != ""

	  UNION ALL
      
	  SELECT 4000,
			 10934,
			 b.code_1099,
			 "",
			 0, 
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #apvovcdt b
		INNER JOIN #apvovchg c ON b.trx_ctrl_num = c.trx_ctrl_num
		INNER JOIN appayto d ON c.vendor_code = d.vendor_code AND c.pay_to_code = d.pay_to_code
  	  WHERE d.flag_1099 = 0
	  AND b.code_1099 != ""

END



IF (SELECT err_type FROM apedterr WHERE err_code = 10930) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 760, 5 ) + " -- MSG: " + "Check if code_1099 is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10930,
			 b.code_1099,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #apvovcdt b
		LEFT JOIN appyt pyt ON b.code_1099 = pyt.code_1099 
  	  WHERE b.code_1099 != ""
	  AND pyt.code_1099 IS NULL
END




IF (SELECT err_type FROM apedterr WHERE err_code = 10932) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 787, 5 ) + " -- MSG: " + "Check if 1099 code is not entered for a 1099 vendor"
	










































      INSERT #ewerror
	  SELECT 4000,
			 10932,
			 b.code_1099,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #apvovcdt b
		INNER JOIN #apvovchg c ON b.trx_ctrl_num = c.trx_ctrl_num
		INNER JOIN apvend d ON c.vendor_code = d.vendor_code
  	  WHERE c.pay_to_code = ""
	  AND d.flag_1099 = 1
	  AND b.code_1099 = ""

	  UNION ALL      

	  SELECT 4000,
			 10932,
			 b.code_1099,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #apvovcdt b
		INNER JOIN #apvovchg c ON b.trx_ctrl_num = c.trx_ctrl_num
		INNER JOIN appayto d ON c.vendor_code = d.vendor_code AND c.pay_to_code = d.pay_to_code
  	  WHERE d.flag_1099 = 1
	  AND b.code_1099 = ""

END







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvedet1.cpp" + ", line " + STR( 877, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvedet1_sp] TO [public]
GO
