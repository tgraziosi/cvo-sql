SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[epvchdtl1_sp] @error_level smallint
AS



IF (SELECT err_type FROM epedterr WHERE err_code = 00230) <= @error_level
BEGIN
  INSERT #ewerror
	  SELECT 4000,
			 00230,
			 b.org_id,
			 '',
			 0.0,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 b.sequence_id,
			 '',
			 0
	  FROM #epvchdtl b
  	  WHERE b.org_id NOT IN ( SELECT org_id FROM dbo.IB_Organization_vw )
END




IF (SELECT err_type FROM epedterr WHERE err_code = 00210) <= @error_level
BEGIN
  INSERT #ewerror
	  SELECT DISTINCT 4000,
			 00210,
			 b.org_id,
			 b.org_id,
			 0.0,
			 0.0,
			 3,
			 a.match_ctrl_num,
			 b.sequence_id,
			 '',
			 0
	 FROM #epvchhdr a, #epvchdtl b, iborgsameandrels_vw r
                    WHERE 
                          a.match_ctrl_num = b.match_ctrl_num
			  AND r.controlling_org_id = a.org_id
			  AND b.org_id NOT IN ( SELECT detail_org_id FROM iborgsameandrels_vw WHERE controlling_org_id = a.org_id )
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00240) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 00240,
			 "",
			 "",
			 0,
			 amt_discount,
			 4,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr
  	  WHERE ((amt_discount) < (0.0) - 0.0000001)
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00250) <= @error_level
BEGIN
   

      INSERT #ewerror
	  SELECT 4000,
			 00250,
			 "",
			 "",
			 0,
			 b.amt_discount,
			 4,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr  b, #epvchdtl c
  	  WHERE b.match_ctrl_num = c.match_ctrl_num
	  GROUP BY b.match_ctrl_num, b.amt_discount
	  HAVING (ABS((b.amt_discount)-(SUM(c.amt_discount))) > 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00260) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 00260,
			 "",
			 "",
			 0,
			 amt_tax,
			 5,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr
  	  WHERE ((amt_tax) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00270) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 00270,
			 "",
			 "",
			 0,
			 amt_tax,
			 4,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr 
  	  WHERE (ABS((amt_tax)-(0.0)) < 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00280) <= @error_level
BEGIN
	
      INSERT #ewerror
	  SELECT 4000,
			 00280,
			 "",
			 "",
			 0,
			 b.amt_tax,
			 4,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, #epvchdtl c
  	  WHERE b.match_ctrl_num = c.match_ctrl_num
	  GROUP BY b.match_ctrl_num, b.amt_tax
	  HAVING (ABS((b.amt_tax)-(SUM(c.amt_tax))) > 0.0000001)
	  AND (ABS((SUM(c.amt_tax))-(0.0)) > 0.0000001)
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00290) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 00290,
			 "",
			 "",
			 0,
			 amt_freight,
			 4,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr 
  	  WHERE ((amt_freight) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00300) <= @error_level
BEGIN
  	

      INSERT #ewerror
	  SELECT 4000,
			 00300,
			 "",
			 "",
			 0,
			 b.amt_freight,
			 4,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, #epvchdtl c
  	  WHERE b.match_ctrl_num = c.match_ctrl_num
	  GROUP BY b.match_ctrl_num, b.amt_freight
	  HAVING 
(ABS((b.amt_freight)-(SUM(c.amt_freight))) > 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00310) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 00310,
			 "",
			 "",
			 0,
			 amt_misc,
			 4,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr
  	  WHERE ((amt_misc) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00320) <= @error_level
BEGIN
	

      INSERT #ewerror
	  SELECT 4000,
			 00320,
			 "",
			 "",
			 0,
			 b.amt_misc,
			 4,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, #epvchdtl c
  	  WHERE b.match_ctrl_num = c.match_ctrl_num
	  GROUP BY b.match_ctrl_num, b.amt_misc
	  HAVING 
(ABS((b.amt_misc)-(SUM(c.amt_misc))) > 0.0000001) 
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00330) <= @error_level
BEGIN
	
	


      INSERT #ewerror
	  SELECT 4000,
			 00330,
			 "",
			 "",
			 0,
			 amt_discount,
			 4,
			 match_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM  #epvchdtl
  	  WHERE ((amt_discount) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00340) <= @error_level
BEGIN
	
	


      INSERT #ewerror
	  SELECT 4000,
			 00340,
			 "",
			 "",
			 0,
			 amt_freight,
			 4,
			 match_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #epvchdtl
  	  WHERE ((amt_freight) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00350) <= @error_level
BEGIN
	
	


      INSERT #ewerror
	  SELECT 4000,
			 00350,
			 "",
			 "",
			 0,
			 amt_tax,
			 4,
			 match_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #epvchdtl
  	  WHERE ((amt_tax) < (0.0) - 0.0000001)
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00360) <= @error_level
BEGIN
	
	


      INSERT #ewerror
	  SELECT 4000,
			 00360,
			 "",
			 "",
			 0,
			 amt_misc,
			 4,
			 match_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #epvchdtl
  	  WHERE ((amt_misc) < (0.0) - 0.0000001)
END







IF (SELECT err_type FROM epedterr WHERE err_code = 00220) <= @error_level
BEGIN

  UPDATE #epvchdtl
	SET flag = 00220
 FROM #epvchhdr a, #epvchdtl b
   WHERE  a.match_ctrl_num = b.match_ctrl_num
	AND a.org_id <> b.org_id

  UPDATE #epvchdtl
	SET flag = 0
   FROM #epvchhdr a, #epvchdtl b, OrganizationOrganizationDef r
   WHERE  a.match_ctrl_num = b.match_ctrl_num
	  AND r.controlling_org_id = a.org_id
	  AND r.detail_org_id = b.org_id
	  AND b.acct_code like r.account_mask 
  INSERT #ewerror
	  SELECT 4000,
			 00220,
			 b.acct_code,
			 '',
			 0.0,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 b.sequence_id,
			 '',
			 0
	 FROM  #epvchdtl b
                    WHERE 
			 b.flag = 00220
			
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[epvchdtl1_sp] TO [public]
GO
