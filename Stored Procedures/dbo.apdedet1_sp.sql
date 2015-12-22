SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


	

CREATE PROCEDURE [dbo].[apdedet1_sp] @error_level smallint, @debug_level smallint = 0
AS
  DECLARE @ib_flag		INTEGER

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 34, 5 ) + " -- ENTRY: "

SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco





IF @ib_flag = 1 
BEGIN
	


	IF (SELECT err_type FROM apedterr WHERE err_code = 21180) <= @error_level
  	BEGIN
	



























		
		
		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 4000,			21180,		a.gl_exp_acct,
			a.trx_ctrl_num,			0,		0.0,
			1,			a.trx_ctrl_num,	a.sequence_id,
			'',			0
		FROM 	#apdmvcdt a 
			INNER JOIN #apdmvchg b ON a.trx_ctrl_num = b.trx_ctrl_num ANd a.trx_type = b.trx_type AND  a.org_id <> b.org_id AND a.rec_company_code = b.company_code  	 -- Rev 1.1
			LEFT JOIN (	
					SELECT a.trx_ctrl_num 
					FROM 	#apdmvchg a
						INNER JOIN #apdmvcdt b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.trx_type = b.trx_type
						INNER JOIN OrganizationOrganizationDef ood ON b.org_id = ood.detail_org_id AND	b.gl_exp_acct LIKE ood.account_mask
					WHERE 	a.org_id = ood.controlling_org_id
					) TEMP ON a.trx_ctrl_num = TEMP.trx_ctrl_num
			WHERE 	b.interbranch_flag = 1
			AND TEMP.trx_ctrl_num IS NULL				

				
	END
	

	


	IF (SELECT err_type FROM apedterr WHERE err_code = 21200) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 115, 5 ) + " -- MSG: " + "Validate organization exists and is active in Detail"



























		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	21200, 		b.org_id,
			b.org_id, 		0, 		0.0,
			1, 			b.trx_ctrl_num, 	b.sequence_id,
			"", 			0
		FROM 	#apdmvcdt b
			INNER JOIN #apdmvchg a ON b.trx_ctrl_num = a.trx_ctrl_num AND b.trx_type = a.trx_type AND b.rec_company_code = a.company_code -- Rev 1.1	
			LEFT JOIN Organization o ON b.org_id = o.organization_id AND o.active_flag = 1
		WHERE o.organization_id IS NULL


  	END

	



	IF (SELECT err_type FROM apedterr WHERE err_code = 21210) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \apinpcdt"

		


		UPDATE 	#apdmvcdt
	        SET 	temp_flag = 0

		



		UPDATE 	#apdmvcdt					
	        SET 	temp_flag = 1
		FROM 	#apdmvcdt a
		WHERE  dbo.IBOrgbyAcct_fn(a.gl_exp_acct)  = a.org_id 
		

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 			21210, 			a.gl_exp_acct,
			a.org_id, 		0, 		0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#apdmvcdt a, #apdmvchg b
		WHERE 	a.temp_flag = 0
		AND	a.trx_ctrl_num = b.trx_ctrl_num		 -- Rev 1.1	
		AND	a.trx_type = b.trx_type			 -- Rev 1.1	
		AND     b.company_code = a.rec_company_code	 -- Rev 1.1	

	END

END

ELSE
BEGIN
	


	IF (SELECT err_type FROM apedterr WHERE err_code = 21220) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same apinpchg/apinpcdt"

		





































		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 			21220, 			b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 		0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#apdmvcdt a
			INNER JOIN #apdmvchg b ON a.trx_ctrl_num = b.trx_ctrl_num AND a.rec_company_code = b.company_code 	 -- Rev 1.1	
			LEFT JOIN #apdmvchg c ON a.trx_ctrl_num = c.trx_ctrl_num ANd a.trx_type = c.trx_type AND a.org_id = c.org_id
		WHERE c.org_id IS NULL

	END
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20840) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 284, 5 ) + " -- MSG: " + "Check if any sequence_id is less than 1"
	


      INSERT #ewerror
	  SELECT 4000,
			 20840,
			 "",
			 "",
			 sequence_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apdmvcdt 
  	  WHERE sequence_id < 1
END

IF ((SELECT intercompany_flag FROM apco) = 1)
   BEGIN

    IF (SELECT err_type FROM apedterr WHERE err_code = 21071) <= @error_level
      BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 309, 5 ) + " -- MSG: " + "Check if recipient company code exists"
			


      		INSERT #ewerror
			SELECT 4000,
				   21071,
				   rec_company_code,
				   "",
				   0,
				   0.0,
				   1,
				   trx_ctrl_num,
				   sequence_id,
				   "",
				   0
			  FROM #apdmvcdt 
		  	  WHERE rec_company_code NOT IN (SELECT company_code FROM glcomp_vw)
	   END


   IF (SELECT err_type FROM apedterr WHERE err_code = 21068) <= @error_level
      BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 332, 5 ) + " -- MSG: " + "Verify intercompany definition"
		


      INSERT #ewerror
	  SELECT 4000,
			 21068,
			 b.rec_company_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
		  FROM #apdmvcdt b, #apdmvchg c
	  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
		  AND c.company_code != b.rec_company_code
		  AND NOT EXISTS (SELECT 1
		  	  			  FROM glcoco_vw d
		  	  			  WHERE d.rec_code = b.rec_company_code
			  			  AND d.org_code = c.company_code 
			  			  AND d.rec_code = b.rec_company_code)

	   END

   IF (SELECT err_type FROM apedterr WHERE err_code = 21041) <= @error_level
       BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 361, 5 ) + " -- MSG: " + "Verify intercompany definition for the expense account"
			


			  UPDATE #apdmvcdt
			  SET flag = 1
			  FROM #apdmvcdt, #apdmvchg b
			  WHERE #apdmvcdt.trx_ctrl_num = b.trx_ctrl_num
			  AND #apdmvcdt.rec_company_code = b.company_code


			  UPDATE #apdmvcdt
			  SET flag = 1
			  FROM #apdmvcdt,  #apdmvchg c, glcocodt_vw d
		  	  WHERE #apdmvcdt.trx_ctrl_num = c.trx_ctrl_num
			  AND c.company_code != #apdmvcdt.rec_company_code
			  AND d.rec_code = #apdmvcdt.rec_company_code
			  AND d.org_code = c.company_code 
			  AND #apdmvcdt.gl_exp_acct LIKE d.account_mask
			  AND #apdmvcdt.flag = 0

		      INSERT #ewerror
			  SELECT 4000,
					 21041,
					 gl_exp_acct,
					 "",
					 0,
					 0.0,
					 1,
					 trx_ctrl_num,
					 sequence_id,
					 "",
					 0
		 	  FROM #apdmvcdt 
		   	  WHERE flag = 0		


	END
  END

ELSE

  BEGIN

	IF (SELECT err_type FROM apedterr WHERE err_code = 21067) <= @error_level
       BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 407, 5 ) + " -- MSG: " + "Check if company codes are same in header and detail"
			


          INSERT #ewerror
	      SELECT 4000,
			 21067,
			 b.rec_company_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
     	  FROM #apdmvcdt b, #apdmvchg c
		  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
			  AND b.rec_company_code != c.company_code
	   END

  END




IF (SELECT err_type FROM apedterr WHERE err_code = 20880) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 435, 5 ) + " -- MSG: " + "Check if qty_returned is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 20880,
			 "",
			 "",
			 0,
			 qty_returned,
			 5,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apdmvcdt 
  	  WHERE ((qty_returned) < (0.0) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20900) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 459, 5 ) + " -- MSG: " + "Check if qty_ordered is negative"
	


      INSERT #ewerror
	  SELECT 4000,
			 20900,
			 "",
			 "",
			 0,
			 qty_ordered,
			 5,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apdmvcdt 
  	  WHERE ((qty_ordered) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20890) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 482, 5 ) + " -- MSG: " + "Check if qty_returned > qty_ordered"
	


      INSERT #ewerror
	  SELECT 4000,
			 20890,
			 "",
			 "",
			 0,
			 qty_returned,
			 5,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apdmvcdt b
  	  WHERE ((qty_returned) > (qty_ordered) + 0.0000001) 
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20920) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 505, 5 ) + " -- MSG: " + "Check if tax code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 20920,
			 tax_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #apdmvcdt 
  	  WHERE tax_code NOT IN (SELECT tax_code FROM aptax)
	  AND tax_code != ""
END

IF (SELECT err_type FROM apedterr WHERE err_code = -20920) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 528, 5 ) + " -- MSG: " + "Check if tax code is valid for tax connect service"
	


	INSERT	#ewerror
	(
		module_id,			err_code,
		info1,				info2,
		infoint,			infofloat,
		flag1,				trx_ctrl_num,
		sequence_id,			source_ctrl_num,
		extra
	)
	SELECT 4000,  	-20920,
		d.tax_code,			'',
		0,				0.0,
		1,			d.trx_ctrl_num,
		d.sequence_id,			'',
		0
	FROM #apdmvchg c 
		join artax tax (nolock) on (c.tax_code = tax.tax_code)
		join #apdmvcdt d on (c.trx_ctrl_num = d.trx_ctrl_num AND c.trx_type = d.trx_type)
		join artax td (nolock) on (d.tax_code = td.tax_code)
	WHERE tax.tax_connect_flag != td.tax_connect_flag	
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdedet1.cpp" + ", line " + STR( 556, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apdedet1_sp] TO [public]
GO
