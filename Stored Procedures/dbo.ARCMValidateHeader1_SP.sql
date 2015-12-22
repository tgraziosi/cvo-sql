SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCMValidateHeader1_SP]	@error_level	smallint,   
					@debug_level	smallint = 0
AS

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh1.cpp" + ", line " + STR( 49, 5 ) + " -- ENTRY: "
	
DECLARE	
	@e_level_1	smallint,
	@e_level_2	smallint,
	@e_level_3	smallint


DECLARE @ib_flag		INTEGER			--AAP

	







	

	
	SELECT 	@ib_flag = 0
	SELECT 	@ib_flag = ib_flag
	FROM 	glco

	
	UPDATE  #arvalchg
	SET     interbranch_flag = 1
	FROM 	#arvalchg a, #arvalcdt b 
	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
	AND   	a.org_id <> b.org_id


if(@ib_flag > 0)
BEGIN
	



	IF ( SELECT e_level FROM aredterr WHERE e_code = 20268 ) >= @error_level
	BEGIN
		UPDATE 	#arvalcdt
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalcdt
	        SET 	temp_flag2 = 1
		FROM 	#arvalchg a, #arvalcdt b, OrganizationOrganizationRel ood
		WHERE 	a.org_id = ood.controlling_org_id			
		AND 	b.org_id = ood.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

		INSERT INTO #ewerror
		(   	module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20268,			a.org_id +'-'+ b.org_id,
			b.org_id, 		user_id, 		0.0,
			0, 			a.trx_ctrl_num, 	0,
			b.trx_ctrl_num, 			0
		FROM 	#arvalchg a,  #arvalcdt b
		WHERE 	a.interbranch_flag = 1
		AND 	b.temp_flag2 = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id
	END

	



	IF ( SELECT e_level FROM aredterr WHERE e_code = 20270 ) >= @error_level
	BEGIN
		UPDATE 	#arvalchg
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalchg
		SET 	temp_flag2 = 1
		FROM 	#arvalchg a, Organization o
		WHERE 	a.org_id = o.organization_id
		AND 	o.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20270, org_id,
			org_id, user_id, 0.0,
			0, trx_ctrl_num, 0, 					
			trx_ctrl_num, 0
		FROM 	#arvalchg
		WHERE 	temp_flag2 = 0
	END

END 	--AAP




	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20200  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	ewusers_vw u, #arvalchg chg
		WHERE  u.user_id = chg.user_id
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20200,
			"",			"",			user_id,
			0.0,			5,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END


	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20201  ) >= @error_level
		
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20201,
			doc_ctrl_num,		"",			0,
			0.0,			0,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg 
		WHERE	printed_flag = 0
	END
	
	



	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20221  ) >= @error_level
		
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20221,
			"",			"",			posted_flag,
			0.0,			5,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	posted_flag < -1 OR posted_flag > 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20223  ) >= @error_level
		
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20223,
			"",			"",			hold_flag,
			0.0,			5,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	hold_flag = 1
	END
	
	



	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20222  ) >= @error_level
		
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20222,
			"",			"",			hold_flag,
			0.0,			5,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	hold_flag < 0 OR hold_flag > 1
	END

	SELECT	@e_level_1 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20202
	SELECT	@e_level_2 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20206	
	SELECT	@e_level_3 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20207

	IF (@e_level_1 + @e_level_2 + @e_level_3 ) > 0 
	BEGIN

		CREATE TABLE #cust_info
			( customer_code 	varchar(8),
			  nat_cur_code	varchar(8) NULL,
			  status_type		smallint NULL,
			  one_cur_cust	smallint NULL,
			  flag			smallint )
	
		INSERT INTO #cust_info (customer_code, flag)
		SELECT	distinct customer_code, 0
		FROM	#arvalchg 
			  	
		UPDATE	#cust_info
		SET	nat_cur_code = c.nat_cur_code,
			status_type = c.status_type,
			one_cur_cust = c.one_cur_cust,
			flag = 1
		FROM	arcust c
		WHERE	#cust_info.customer_code = c.customer_code
	
	END

	


	IF @e_level_1 = 1 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh1.cpp" + ", line " + STR( 304, 5 ) + " -- MSG: " + "Validate the customer_code exists in the customer table"
		
		INSERT	#ewerror
		SELECT 2000,
		  	20202,
			a.customer_code,
			"",
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalchg a, #cust_info c
	  	WHERE 	a.customer_code = c.customer_code
		AND	c.flag = 0
	END
	
	


	IF @e_level_2 = 1 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh1.cpp" + ", line " + STR( 328, 5 ) + " -- MSG: " + "Validate the customer is active"
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20206,
			a.customer_code,
			"",
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalchg a, #cust_info c
	  	WHERE	a.customer_code = c.customer_code
		AND	c.status_type >= 2
	END


	



	IF @e_level_3 = 1 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh1.cpp" + ", line " + STR( 357, 5 ) + " -- MSG: " + "Validate the transaction currency is valid for this customer code"
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20207,
			a.customer_code + "--" + a.nat_cur_code,
			"",
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalchg a, #cust_info c
	  	WHERE	a.customer_code = c.customer_code
		AND	c.one_cur_cust = 1
		AND	a.nat_cur_code != c.nat_cur_code
	END

	
	IF (@e_level_1 + @e_level_2 + @e_level_3 ) > 0 
		DROP TABLE #cust_info

	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20205  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = " " )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	batchctl bat, #arvalchg chg
		WHERE	bat.batch_ctrl_num = chg.batch_code
		AND	chg.temp_flag = 0
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20205,
			chg.batch_code,	"",			0,
			0.0,			0,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg
		WHERE	temp_flag = 0
	END
	
	
	SELECT	@e_level_1 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20210
	SELECT	@e_level_2 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20211	

	IF (@e_level_1 + @e_level_2 ) > 0 
	BEGIN

		CREATE TABLE #ship_info
			( customer_code 	varchar(8),
			  ship_to_code	varchar(8) ,
			  nat_cur_code	varchar(8) NULL,
			  one_cur_cust	smallint NULL,
			  flag			smallint )
	
		INSERT INTO #ship_info (customer_code, ship_to_code,flag)
		SELECT	distinct customer_code, ship_to_code, 0
		FROM	#arvalchg 
		WHERE	( LTRIM(ship_to_code) IS NOT NULL AND LTRIM(ship_to_code) != " " )
			  	
		UPDATE	#ship_info
		SET	nat_cur_code = c.nat_cur_code,
			one_cur_cust = c.one_cur_cust,
			flag = 1
		FROM	armaster c
		WHERE	#ship_info.customer_code = c.customer_code
		AND	#ship_info.ship_to_code = c.ship_to_code
		AND	c.address_type = 1
	
	END

	


	IF @e_level_1 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh1.cpp" + ", line " + STR( 453, 5 ) + " -- MSG: " + "Validate the ship_to_code exists for this customer "
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20210,
			a.ship_to_code,
			"",
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			"",
			0
		FROM 	#arvalchg a, #ship_info b
	  	WHERE 	a.customer_code = b.customer_code
	  	AND	a.ship_to_code = b.ship_to_code
	  	AND	flag = 0 
	END
	

	


	IF @e_level_2 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh1.cpp" + ", line " + STR( 482, 5 ) + " -- MSG: " + "Validate the ship_to_code is valid for the currency of the transaction "
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20211,
			a.ship_to_code,
			"",
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			"",
			0
		FROM #arvalchg a, #ship_info b
	  	WHERE a.customer_code = b.customer_code 
		AND	a.ship_to_code = b.ship_to_code
		AND	b.one_cur_cust = 1
		AND	a.nat_cur_code != b.nat_cur_code
		
	END

	IF (@e_level_1 + @e_level_2 ) > 0 
		DROP TABLE #ship_info
	
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20212  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(salesperson_code) IS NULL OR LTRIM(salesperson_code) = " " )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arsalesp sales, #arvalchg chg
		WHERE	sales.salesperson_code = chg.salesperson_code
		AND	chg.temp_flag = 0
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20212,
			chg.salesperson_code,	"",		0,
			0.0,			0,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20213  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20213,
			chg.salesperson_code,	"",		0,
			0.0,			0,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg, arsalesp sales
		WHERE	chg.salesperson_code = sales.salesperson_code
		AND	sales.status_type >= 2  
	END

      	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20214  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(territory_code) IS NULL OR LTRIM(territory_code) = " " )
				
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arterr ter, #arvalchg chg
		WHERE	ter.territory_code = chg.territory_code
		AND	chg.temp_flag = 0
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20214,
			chg.territory_code,	"",			0,
			0.0,			0,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20215  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(price_code) IS NULL OR LTRIM(price_code) = " " )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arprice price, #arvalchg chg
		WHERE	price.price_code = chg.price_code
		AND	chg.temp_flag = 0
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20215,
			price_code,		"",			0,
			0.0,			0,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh1.cpp" + ", line " + STR( 636, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCMValidateHeader1_SP] TO [public]
GO
