SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARCRValidateHeader1_SP] @error_level smallint, 
 @debug_level smallint = 0
AS

DECLARE 
 @result smallint,
 @min_period_start_date int,
 @max_period_end_date int,
 @ib_flag		  int


BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 36, 5 ) + " -- ENTRY: "

 
 
 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20400) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 68, 5 ) + " -- MSG: " + "Validate user id exists"

 /*UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM ewusers_vw ew
 WHERE #arvalpyt.user_id = ew.user_id
 

 INSERT #ewerror
 SELECT 2000,
 20400,
 "",
 "",
 user_id,
 0.0,
 2,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0*/
 
 INSERT #ewerror
 SELECT 2000,
 20400,
 "",
 "",
 user_id,
 0.0,
 2,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE NOT EXISTS (Select 1 from ewusers_vw ew where #arvalpyt.user_id = ew.user_id ) 


 END

	
	SELECT 	@ib_flag = 0
	SELECT 	@ib_flag = ib_flag
	FROM 	glco

	
	UPDATE  #arvalpyt
	SET     interbranch_flag = 1
	FROM 	#arvalpyt a, #arvalpdt b 
	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
	AND   	a.org_id <> b.org_id


	
	UPDATE  #arvalpyt
	SET     interbranch_flag = 1
	FROM 	#arvalpyt a, #arvalnonardet b
	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
	AND   	a.org_id <> b.org_id

if(@ib_flag > 0)
BEGIN
	



	IF ( SELECT e_level FROM aredterr WHERE e_code = 20432 ) >= @error_level
	BEGIN
		/*UPDATE 	#arvalpyt
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalpyt
		SET 	temp_flag2 = 1
		FROM 	#arvalpyt a, Organization o
		WHERE 	a.org_id = o.organization_id
		AND 	o.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20432, org_id,
			org_id, user_id, 0.0,
			1, trx_ctrl_num, -1,
			trx_ctrl_num, 0
		FROM 	#arvalpyt
		WHERE 	temp_flag2 = 0*/

		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20432, org_id,
			org_id, user_id, 0.0,
			1, trx_ctrl_num, -1,
			trx_ctrl_num, 0
		FROM 	#arvalpyt
		WHERE 	NOT EXISTS (Select 1 from Organization o where #arvalpyt.org_id = o.organization_id AND o.active_flag = 1) 

	END

	



	IF ( SELECT e_level FROM aredterr WHERE e_code = 20431 ) >= @error_level
	BEGIN
		/*UPDATE 	#arvalpdt
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalpdt
	        SET 	temp_flag2 = 1
		FROM 	#arvalpyt a, #arvalpdt b, OrganizationOrganizationRel oor
		WHERE 	a.org_id = oor.controlling_org_id			
		AND 	b.org_id = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

		INSERT INTO #ewerror
		(   	module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20431,			a.org_id +'-'+ b.org_id,
			b.org_id, 		user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	0,
			b.trx_ctrl_num, 			0
		FROM 	#arvalpyt a,  #arvalpdt b
		WHERE 	a.interbranch_flag = 1
		AND 	b.temp_flag2 = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id*/
		
		INSERT INTO #ewerror
		(   	module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20431,			a.org_id +'-'+ b.org_id,
			b.org_id, 		user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	0,
			b.trx_ctrl_num, 			0
		FROM 	#arvalpyt a,  #arvalpdt b
		WHERE 	a.interbranch_flag = 1
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id
		AND     NOT EXISTS (SELECT 1 FROM OrganizationOrganizationRel oor WHERE a.org_id = oor.controlling_org_id			
		AND 	b.org_id = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num  )

		
	END

	




	IF ( SELECT e_level FROM aredterr WHERE e_code = 20431 ) >= @error_level
	BEGIN
		/*UPDATE 	#arvalnonardet
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalnonardet
	        SET 	temp_flag2 = 1
		FROM 	#arvalpyt a, #arvalnonardet b, OrganizationOrganizationRel oor
		WHERE 	a.org_id = oor.controlling_org_id			
		AND 	b.org_id = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

		INSERT INTO #ewerror
		(   	module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20431,			a.org_id +'-'+ b.org_id,
			b.org_id, 		user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	0,
			b.trx_ctrl_num, 			0
		FROM 	#arvalpyt a,  #arvalnonardet b
		WHERE 	a.interbranch_flag = 1
		AND 	b.temp_flag2 = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id*/

		INSERT INTO #ewerror
		(   	module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20431,			a.org_id +'-'+ b.org_id,
			b.org_id, 		user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	0,
			b.trx_ctrl_num, 			0
		FROM 	#arvalpyt a,  #arvalnonardet b
		WHERE 	a.interbranch_flag = 1
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id 
		AND     NOT EXISTS (SELECT 1 FROM OrganizationOrganizationRel oor WHERE a.org_id = oor.controlling_org_id			
		AND 	b.org_id = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num  )
		

	END

END


 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20401) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 100, 5 ) + " -- MSG: " + "Validate customer code exists"

 /*UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM arcust
 WHERE #arvalpyt.customer_code = arcust.customer_code
 

 INSERT #ewerror
 SELECT 2000,
 20401,
 customer_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0*/


 INSERT #ewerror
 SELECT 2000,
 20401,
 customer_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt #arvalpyt
 WHERE NOT EXISTS(select 1 from arcust where #arvalpyt.customer_code = arcust.customer_code)

 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20402) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 132, 5 ) + " -- MSG: " + "Validate payment type"

 UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 WHERE #arvalpyt.non_ar_flag = 0
 AND #arvalpyt.payment_type >= 1
 AND #arvalpyt.payment_type <= 4

 
 UPDATE #arvalpyt
 SET temp_flag = 1
 WHERE non_ar_flag = 1
 AND payment_type >= 0
 AND payment_type <= 1 

 INSERT #ewerror
 SELECT 2000,
 20402,
 "",
 "",
 payment_type,
 0.0,
 2,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20404) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 171, 5 ) + " -- MSG: " + "Validate payment code exists"

/* UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM arpymeth
 WHERE #arvalpyt.payment_code = arpymeth.payment_code
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 WHERE payment_type >= 3
 AND payment_type <= 4

 INSERT #ewerror
 SELECT 2000,
 20404,
 payment_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0*/

 INSERT #ewerror
 SELECT 2000,
 20404,
 payment_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt #arvalpyt 
 WHERE payment_type < 3
 AND payment_type > 4
 AND NOT EXISTS (select 1 from arpymeth arpymeth where #arvalpyt.payment_code = arpymeth.payment_code )


 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20417) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 207, 5 ) + " -- MSG: " + "Validate the home rate type exists"

 /*UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM glrtype_vw gl
 WHERE #arvalpyt.rate_type_home = gl.rate_type
 

 INSERT #ewerror
 SELECT 2000,
 20417,
 rate_type_home,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0*/

 INSERT #ewerror
 SELECT 2000,
 20417,
 rate_type_home,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE NOT EXISTS (select 1 from glrtype_vw gl where #arvalpyt.rate_type_home = gl.rate_type )

 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20418) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 239, 5 ) + " -- MSG: " + "Validate the operational rate type exists"

/* UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM glrtype_vw gl
 WHERE #arvalpyt.rate_type_oper = gl.rate_type
 

 INSERT #ewerror
 SELECT 2000,
 20418,
 rate_type_oper,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0*/

 INSERT #ewerror
 SELECT 2000,
 20418,
 rate_type_oper,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt #arvalpyt
 WHERE not exists (select 1 from glrtype_vw gl where #arvalpyt.rate_type_oper = gl.rate_type )

 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20420) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 271, 5 ) + " -- MSG: " + "Validate the home rate is not 0.0"

 INSERT #ewerror
 SELECT 2000,
 20420,
 rate_type_home,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE (ABS((rate_home)-(0.0)) < 0.0000001)
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20419) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 294, 5 ) + " -- MSG: " + "Validate the operational rate is not 0.0"

 INSERT #ewerror
 SELECT 2000,
 20419,
 rate_type_oper,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE (ABS((rate_oper)-(0.0)) < 0.0000001)
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20421) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 317, 5 ) + " -- MSG: " + "Validate the currency code exists"

 /*UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM glcurr_vw gl
 WHERE #arvalpyt.nat_cur_code = gl.currency_code
 

 INSERT #ewerror
 SELECT 2000,
 20421,
 nat_cur_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0*/

 INSERT #ewerror
 SELECT 2000,
 20421,
 nat_cur_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt #arvalpyt
 WHERE not exists ( select 1 from  glcurr_vw gl where #arvalpyt.nat_cur_code = gl.currency_code )



 END


 SELECT @min_period_start_date = min(period_start_date),
 @max_period_end_date = max(period_end_date)
 FROM glprd
 
 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20427 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 354, 5 ) + " -- MSG: " + "Check if applied date is for a future period"
 
 
 INSERT #ewerror
 SELECT 2000,
 20427,
 "",
 "",
 date_applied,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt a, arco b
 WHERE a.date_applied > b.period_end_date
 END

 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20428 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 380, 5 ) + " -- MSG: " + "Check if apply date is to a prior period"
 
 
 INSERT #ewerror
 SELECT 2000,
 20428,
 "",
 "",
 a.date_applied,
 0.0,
 3,
 a.trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt a, glprd b, arco c
 WHERE a.date_applied < b.period_start_date
 AND b.period_end_date = c.period_end_date
 END

 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20429 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 407, 5 ) + " -- MSG: " + "Check if apply date does not fall within any period defined in GL"
 
 
 INSERT #ewerror
 SELECT 2000,
 20429,
 "",
 "",
 date_applied,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt 
 WHERE date_applied < @min_period_start_date
 OR date_applied > @max_period_end_date
 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20430 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 435, 5 ) + " -- MSG: " + "Check if the apply date is not in the range specified on the Name and Options form"
 
 
 INSERT #ewerror
 SELECT 2000,
 20430,
 "",
 "",
 date_applied,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalpyt a, arco b
 WHERE ABS(a.date_applied - a.date_entered) > b.date_range_verify
 END

 RETURN 0
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrvh1.sp" + ", line " + STR( 457, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCRValidateHeader1_SP] TO [public]
GO
