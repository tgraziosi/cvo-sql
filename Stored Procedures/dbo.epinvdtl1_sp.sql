SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[epinvdtl1_sp] @only_errors smallint
AS
	DECLARE @error_level smallint


IF @only_errors = 1
	SELECT @error_level = 0
ELSE 
	SELECT @error_level = 1



IF (SELECT err_type FROM epedterr WHERE err_code = 10130) <= @error_level
BEGIN

 SELECT receipt_ctrl_num, sequence_id, count(*) counter
 INTO   #invalid_sequence_id
 FROM   #epinvdtl
 GROUP BY receipt_ctrl_num, sequence_id
 HAVING count(*) > 1
	 
 INSERT #ewerror
	 SELECT 4000,
			 10130,
			 '',
			 '',
			 a.sequence_id,
			 0.0,
			 2,
			 a.receipt_ctrl_num,
			 a.sequence_id,
			 '',
			 0
	 FROM #epinvdtl a, #invalid_sequence_id b
	 WHERE a.receipt_ctrl_num = b.receipt_ctrl_num
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10140) <= @error_level
BEGIN
	 
 INSERT #ewerror
	 SELECT 4000,
			 10140,
			 '',
			 '',
			 0,
			 qty_received,
			 5,
			 receipt_ctrl_num,
			 sequence_id,
			 "",
			 0
	FROM #epinvdtl
  	  WHERE ((qty_received) < (0.0) - 0.0000001)


END


IF (SELECT err_type FROM epedterr WHERE err_code = 10180) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 10180,
			 "",
			 "",
			 0,
			 amt_discount,
			 4,
			 receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr 
  	  WHERE ((amt_discount) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM epedterr WHERE err_code = 10190) <= @error_level
BEGIN
   

      INSERT #ewerror
	  SELECT 4000,
			 10190,
			 "",
			 "",
			 0,
			 b.amt_discount,
			 4,
			 b.receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr  b, #epinvdtl c
  	  WHERE b.receipt_ctrl_num = c.receipt_ctrl_num
	  GROUP BY b.receipt_ctrl_num, b.amt_discount
	  HAVING (ABS((b.amt_discount)-(SUM(c.amt_discount))) > 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10200) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 10200,
			 "",
			 "",
			 0,
			 amt_tax,
			 5,
			 receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr
  	  WHERE ((amt_tax) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10210) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 10210,
			 "",
			 "",
			 0,
			 amt_tax,
			 4,
			 receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr 
  	  WHERE (ABS((amt_tax)-(0.0)) < 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10220) <= @error_level
BEGIN
	
      INSERT #ewerror
	  SELECT 4000,
			 10220,
			 "",
			 "",
			 0,
			 b.amt_tax,
			 4,
			 b.receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr b, #epinvdtl c
  	  WHERE b.receipt_ctrl_num = c.receipt_ctrl_num
	  GROUP BY b.receipt_ctrl_num, b.amt_tax
	  HAVING (ABS((b.amt_tax)-(SUM(c.amt_tax))) > 0.0000001)
	  AND (ABS((SUM(c.amt_tax))-(0.0)) > 0.0000001)
END


IF (SELECT err_type FROM epedterr WHERE err_code = 10240) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 10240,
			 "",
			 "",
			 0,
			 amt_freight,
			 4,
			 receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr 
  	  WHERE ((amt_freight) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10250) <= @error_level
BEGIN
  	

      INSERT #ewerror
	  SELECT 4000,
			 10250,
			 "",
			 "",
			 0,
			 b.amt_freight,
			 4,
			 b.receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr b, #epinvdtl c
  	  WHERE b.receipt_ctrl_num = c.receipt_ctrl_num
	  GROUP BY b.receipt_ctrl_num, b.amt_freight
	  HAVING 
(ABS((b.amt_freight)-(SUM(c.amt_freight))) > 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10260) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 10260,
			 "",
			 "",
			 0,
			 amt_misc,
			 4,
			 receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr
  	  WHERE ((amt_misc) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10270) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 10270,
			 "",
			 "",
			 0,
			 b.amt_misc,
			 4,
			 b.receipt_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epinvhdr b, #epinvdtl c
  	  WHERE b.receipt_ctrl_num = c.receipt_ctrl_num
	  GROUP BY b.receipt_ctrl_num, b.amt_misc
	  HAVING 
(ABS((b.amt_misc)-(SUM(c.amt_misc))) > 0.0000001) 
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10280) <= @error_level
BEGIN
	
	


      INSERT #ewerror
	  SELECT 4000,
			 10280,
			 "",
			 "",
			 0,
			 amt_discount,
			 4,
			 receipt_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM  #epinvdtl
  	  WHERE ((amt_discount) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10290) <= @error_level
BEGIN
	
	


      INSERT #ewerror
	  SELECT 4000,
			 10290,
			 "",
			 "",
			 0,
			 amt_freight,
			 4,
			 receipt_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #epinvdtl
  	  WHERE ((amt_freight) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10300) <= @error_level
BEGIN
	
	


      INSERT #ewerror
	  SELECT 4000,
			 10300,
			 "",
			 "",
			 0,
			 amt_tax,
			 4,
			 receipt_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #epinvdtl
  	  WHERE ((amt_tax) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 10310) <= @error_level
BEGIN
	
	


      INSERT #ewerror
	  SELECT 4000,
			 10310,
			 "",
			 "",
			 0,
			 amt_misc,
			 4,
			 receipt_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #epinvdtl
  	  WHERE ((amt_misc) < (0.0) - 0.0000001)
END



IF ((SELECT intercompany_flag FROM apco) = 1)
BEGIN

	IF (SELECT err_type FROM epedterr WHERE err_code = 10170) <= @error_level
	BEGIN
		
 		INSERT #ewerror
		SELECT 4000,
				 10170,
				 '',
				 '',
				 company_id,
				 0.0,
				 2,
				 receipt_ctrl_num,
				 sequence_id,
				 "",
				 0
		FROM #epinvdtl
		WHERE company_id NOT IN (SELECT company_id FROM glcomp_vw)
	END


	IF (SELECT err_type FROM epedterr WHERE err_code = 10150) <= @error_level
	BEGIN
		
		INSERT #ewerror
		SELECT 4000,
			 10150,
			 '',
			 '',
			 b.company_id,
			 0.0,
			 1,
			 b.receipt_ctrl_num,
			 b.sequence_id,
			 "",
			 0
		FROM #epinvdtl b, #epinvhdr c
		WHERE b.receipt_ctrl_num = c.receipt_ctrl_num
		AND c.company_code != b.company_code
		AND NOT EXISTS (SELECT *
			FROM glcoco_vw d
			WHERE d.rec_code = b.company_code
			AND d.org_code = c.company_code 
			AND d.rec_code = b.company_code)

	END

	IF (SELECT err_type FROM epedterr WHERE err_code = 10080) <= @error_level
	BEGIN
		UPDATE #epinvdtl
		SET flag = 1
		FROM #epinvdtl, #epinvhdr b
		WHERE #epinvdtl.receipt_ctrl_num = b.receipt_ctrl_num
		AND #epinvdtl.company_code = b.company_code


		UPDATE #epinvdtl
		SET flag = 1
		FROM #epinvdtl,  #epinvhdr c, glcocodt_vw d
		WHERE #epinvdtl.receipt_ctrl_num = c.receipt_ctrl_num
		AND c.company_code != #epinvdtl.company_code
		AND d.rec_code = #epinvdtl.company_code
		AND d.org_code = c.company_code 
		AND #epinvdtl.account_code LIKE d.account_mask

		INSERT #ewerror
		SELECT 	4000,
			10080,
			account_code,
			'',
			0,
			0.0,
			1,
			receipt_ctrl_num,
			sequence_id,
			"",
			0
		 FROM #epinvdtl
		 WHERE flag = 0		
	END
END
ELSE
BEGIN
	IF (SELECT err_type FROM epedterr WHERE err_code = 10160) <= @error_level
	BEGIN
		
		INSERT #ewerror
		SELECT 4000,
			 10160,
			 b.company_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.receipt_ctrl_num,
			 b.sequence_id,
			 "",
			 0
		FROM #epinvhdr a, #epinvdtl b
	 	 WHERE a.receipt_ctrl_num = b.receipt_ctrl_num
		 AND a.company_code != b.company_code
	END
END



INSERT #accounts
SELECT d.db_name,
	b.receipt_ctrl_num,
	b.sequence_id,
	1,
	b.account_code,
	c.date_accepted,
	b.reference_code,
	0
FROM #epinvdtl b, #epinvhdr c, glcomp_vw d
WHERE b.receipt_ctrl_num = c.receipt_ctrl_num
AND b.company_id = d.company_id


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[epinvdtl1_sp] TO [public]
GO
