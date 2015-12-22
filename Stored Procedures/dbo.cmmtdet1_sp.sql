SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cmmtdet1_sp] @error_level smallint, @debug_level smallint = 0
AS

DECLARE @ib_flag		      INTEGER        
DECLARE @interbranch_flag             INTEGER        

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "


SELECT @ib_flag = 0
SELECT @ib_flag = ib_flag 
FROM glco


IF @ib_flag > 0
BEGIN

        IF (SELECT err_type FROM cmedterr WHERE err_code = 10260) <= @error_level
	BEGIN

	        


                IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 52, 5 ) + " -- MSG: " + "Validate if account mapping exists for detail"

        	UPDATE 	#cmmtvdtl
	        SET 	temp_flag = 0

        	UPDATE 	#cmmtvdtl
	        SET 	temp_flag = 1
        	FROM 	#cmmtvhdr h, #cmmtvdtl a, OrganizationOrganizationDef ood
                WHERE 	h.trx_ctrl_num = a.trx_ctrl_num 
				AND 	h.trx_type = a.trx_type	
				AND 	h.org_id = ood.controlling_org_id
				AND 	a.org_id = ood.detail_org_id
		        AND 	a.account_code LIKE ood.account_mask			

        	INSERT INTO #ewerror
	        (       module_id,      err_code,       info1,
		        info2,          infoint,        infofloat,
        		flag1,          trx_ctrl_num,   sequence_id,
	        	source_ctrl_num,extra
        	)
	        SELECT 7000, 10260,       a.org_id,
		        a.org_id,         "",            0.0,
        		1,              a.trx_ctrl_num,  a.sequence_id,
	        	"",             0
        	FROM 	#cmmtvdtl a, #cmmtvhdr b 
                WHERE   a.trx_ctrl_num =  b.trx_ctrl_num
                        AND     b.interbranch_flag = 1
                        AND     a.sequence_id > -1
                        AND 	a.temp_flag = 0
			AND 	a.org_id <> b.org_id
        END


        IF (SELECT err_type FROM cmedterr WHERE err_code = 10270) <= @error_level
	BEGIN

        	


        
                IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 91, 5 ) + " -- MSG: " + "Validate branch exists and is active in Detail"
        
                UPDATE #cmmtvdtl
                SET temp_flag = 0
        
        	UPDATE #cmmtvdtl        
                SET temp_flag = 1
                FROM #cmmtvdtl b, Organization c
                WHERE b.org_id = c.organization_id
                        AND c.active_flag = 1
               
        
        	INSERT INTO #ewerror
        	(       module_id,      err_code,       info1,
        		info2,          infoint,        infofloat,
        		flag1,          trx_ctrl_num,   sequence_id,
        		source_ctrl_num,extra
        	)
        	SELECT 7000, 10270,       a.org_id,
        		a.org_id,         0,             0.0,
        		1,              a.trx_ctrl_num,  a.sequence_id,
        		"",             0
        	FROM 	#cmmtvdtl a, #cmmtvhdr b  
        	WHERE 	a.trx_ctrl_num =  b.trx_ctrl_num
                        AND     b.interbranch_flag = 1
                        AND     a.sequence_id > -1                
        	        AND 	a.temp_flag = 0
        END

	



	IF (SELECT err_type FROM cmedterr WHERE err_code = 10280) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \cmmtdet1"

		


		UPDATE 	#cmmtvdtl
	        SET 	temp_flag = 0

		



		UPDATE 	#cmmtvdtl
	        SET 	temp_flag = 1
		FROM 	#cmmtvdtl a
  		WHERE  dbo.IBOrgbyAcct_fn(a.account_code)  = a.org_id
	

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	7000, 10280, 		a.account_code,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#cmmtvdtl a
		WHERE 	a.temp_flag = 0
	END	-- AAP

END


ELSE
BEGIN
	


	IF (SELECT err_type FROM cmedterr WHERE err_code = 10290) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same \cmmtdet1"
		


		UPDATE 	#cmmtvdtl
	        SET 	temp_flag = 0

		



		UPDATE 	#cmmtvdtl
	        SET 	temp_flag = 1
		FROM 	#cmmtvdtl a, #cmmtvhdr b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND 	a.org_id = b.org_id

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	7000, 10290, 		b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#cmmtvdtl a, #cmmtvhdr b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.temp_flag = 0
	END	
END	--AAP


IF (SELECT err_type FROM cmedterr WHERE err_code = 10140) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 220, 5 ) + " -- MSG: " + "Check if any sequence_id is less than 1"
	


      INSERT #ewerror
	  SELECT 7000,
			 10140,
			 "",
			 "",
			 sequence_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #cmmtvdtl
  	  WHERE sequence_id < 1
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10220) <= @error_level
BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 243, 5 ) + " -- MSG: " + "Check if reference code exists in GL"
      INSERT #ewerror
	  SELECT 7000,
			 10220,
			 reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM  #cmmtvdtl b 
	  WHERE b.reference_code NOT IN (SELECT reference_code FROM glref)    
	  AND b.reference_code != ''
END

IF (SELECT err_type FROM apedterr WHERE err_code = 10190) <= @error_level
BEGIN

  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 264, 5 ) + " -- MSG: " + "Check if reference code is required"
      UPDATE #cmmtvdtl
	  SET flag = 1
	  FROM #cmmtvdtl, glrefact b
	  WHERE #cmmtvdtl.account_code LIKE b.account_mask
	  AND b.reference_flag = 1
	  AND #cmmtvdtl.reference_code = ''


      INSERT #ewerror
	  SELECT 7000,
			 10190,
			 a.account_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM  #cmmtvdtl a, glrefact b
	  WHERE
		 a.account_code LIKE b.account_mask
	  AND b.reference_flag = 3
	  AND a.reference_code = ""
	  AND a.flag = 0

	  UPDATE #cmmtvdtl
	  SET flag = 0
	  WHERE flag <> 0
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 299, 5 ) + " -- MSG: " + "Check if reference code is excluded invalid"
	  



      UPDATE #cmmtvdtl
	  SET flag = 1
	  FROM #cmmtvdtl, glref b, glrefact c, glratyp d
	  WHERE #cmmtvdtl.account_code LIKE c.account_mask
	  AND #cmmtvdtl.reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag = 1
	  AND d.reference_type = b.reference_type
	  AND #cmmtvdtl.reference_code != ""

IF (SELECT err_type FROM apedterr WHERE err_code = 10200) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 10200,
			 reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM  #cmmtvdtl a
	  WHERE a.flag = 1
END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 337, 5 ) + " -- MSG: " + "Check if reference code is not allowed"
	  


      UPDATE #cmmtvdtl
	  SET flag = 2
	  FROM #cmmtvdtl, glrefact b
	  WHERE #cmmtvdtl.account_code LIKE b.account_mask
	  AND #cmmtvdtl.reference_code != ""
	  AND b.reference_flag IN (2,3)
	  AND #cmmtvdtl.flag = 0

IF (SELECT err_type FROM apedterr WHERE err_code = 10200) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 10200,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM  #cmmtvdtl a
	  WHERE a.flag = 0
	  AND a.reference_code != ""
END


	 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 376, 5 ) + " -- MSG: " + "Check if reference code is required or optional and invalid"
	  


      UPDATE #cmmtvdtl
	  SET flag = 3
	  FROM #cmmtvdtl, glref b, glrefact c, glratyp d
	  WHERE #cmmtvdtl.account_code LIKE c.account_mask
	  AND #cmmtvdtl.reference_code = b.reference_code
	  AND c.account_mask = d.account_mask
	  AND c.reference_flag IN (2,3)
	  AND d.reference_type = b.reference_type
	  AND #cmmtvdtl.reference_code != ""
	  AND #cmmtvdtl.flag = 2

IF (SELECT err_type FROM apedterr WHERE err_code = 10210) <= @error_level
BEGIN
	  


      INSERT #ewerror
	  SELECT 7000,
			 10210,
			 a.reference_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM  #cmmtvdtl a
	  WHERE a.flag = 2
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtdet1.cpp" + ", line " + STR( 413, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[cmmtdet1_sp] TO [public]
GO
