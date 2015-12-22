SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[ARCMValidateHeader2_SP]	@error_level	smallint,
					@debug_level	smallint = 0
AS

DECLARE
	@inv_exists_flag	smallint,
	@inv_pif_flag		smallint

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmvh2.cpp' + ', line ' + STR( 47, 5 ) + ' -- ENTRY: '

	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20216  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(dest_zone_code) IS NULL OR LTRIM(dest_zone_code) = ' ' )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arzone zone, #arvalchg chg
		WHERE  zone.zone_code = chg.dest_zone_code
		AND	chg.temp_flag = 0
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20216,
			dest_zone_code,	'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20217  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(comment_code) IS NULL OR LTRIM(comment_code) = ' ' )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arcommnt com, #arvalchg chg
		WHERE  com.comment_code = chg.comment_code
		AND	chg.temp_flag = 0
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20217,
			comment_code,		'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20218  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(fob_code) IS NULL OR LTRIM(fob_code) = ' ' )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arfob fob, #arvalchg chg
		WHERE	fob.fob_code = chg.fob_code
		AND	chg.temp_flag = 0
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20218,
			fob_code,		'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20219  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(freight_code) IS NULL OR LTRIM(freight_code) = ' ' )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arfrate fr, #arvalchg chg
		WHERE	fr.freight_code = chg.freight_code
		AND	chg.temp_flag = 0
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20219,
			freight_code,		'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20220  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	artax tax, #arvalchg chg
		WHERE	tax.tax_code = chg.tax_code
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20220,
			tax_code,		'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20240  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	glcurr_vw curr, #arvalchg chg
		WHERE	curr.currency_code = chg.nat_cur_code
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20240,
			nat_cur_code,		'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	



	IF ( SELECT e_level FROM aredterr WHERE e_code = 20109 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmvh2.cpp' + ', line ' + STR( 249, 5 ) + ' -- MSG: ' + 'Validate that the Currency is valid for tax connect'
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20274,
			a.doc_ctrl_num,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			'',
			0
		FROM   #arvalchg a, artax t
	  	WHERE  a.tax_code = t.tax_code
		AND	t.tax_connect_flag = 1 AND NOT EXISTS(SELECT currency_code from gltc_currency 
													where gltc_currency.currency_code = a.nat_cur_code)
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20241  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	glrtype_vw type, #arvalchg chg
		WHERE	chg.rate_type_home = type.rate_type
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20241,
			rate_type_home,	'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20242  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	glrtype_vw type, #arvalchg chg
		WHERE	chg.rate_type_oper = type.rate_type
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20242,
			rate_type_oper,	'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	



	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20203  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20203,
			vchg.apply_to_num,	'',			0,
			0.0,			0,		vchg.trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg vchg, arinpchg ichg
		WHERE	vchg.apply_to_num = ichg.apply_to_num
		AND	( LTRIM(vchg.apply_to_num) IS NOT NULL AND LTRIM(vchg.apply_to_num) != ' ' )
		AND	vchg.trx_ctrl_num != ichg.trx_ctrl_num
		AND	ichg.trx_type = 2032
	END
	
	



	SELECT @inv_exists_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20204
	
	SELECT @inv_pif_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20265
	
	IF (@inv_exists_flag+@inv_pif_flag) >= 1
	BEGIN
		





		UPDATE	#arvalchg
		SET	temp_flag = 3
		
		UPDATE	#arvalchg
		SET	temp_flag = 2
		WHERE	( LTRIM(apply_to_num) IS NULL OR LTRIM(apply_to_num) = ' ' )
		
		UPDATE	#arvalchg
		SET	temp_flag = paid_flag
		FROM	#arvalchg chg, artrx trx
		WHERE	chg.apply_to_num = trx.doc_ctrl_num
		AND	trx.trx_type <= 2031
		AND	chg.temp_flag = 3
	
		IF ( @inv_exists_flag = 1 )
			


			INSERT	#ewerror
			(	module_id,   					err_code,		
				info1,			info2,			infoint,
				infofloat,		flag1,			trx_ctrl_num,
				sequence_id,		source_ctrl_num,	extra
			)
			SELECT 2000,			20204,
				apply_to_num,		'',			0,
				0.0,			0,		trx_ctrl_num,
				0,			'',			0				
			FROM	#arvalchg
			WHERE	temp_flag = 3
			
		IF ( @inv_pif_flag = 1 )
			


			INSERT	#ewerror
			(	module_id,   					err_code,		
				info1,			info2,			infoint,
				infofloat,		flag1,			trx_ctrl_num,
				sequence_id,		source_ctrl_num,	extra
			)
			SELECT 2000,			20265,
				apply_to_num,		'',			0,
				0.0,			0,		trx_ctrl_num,
				0,			'',			0				
			FROM	#arvalchg
			WHERE	temp_flag = 1

	END


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmvh2.cpp' + ', line ' + STR( 427, 5 ) + ' -- EXIT: '
END
GO
GRANT EXECUTE ON  [dbo].[ARCMValidateHeader2_SP] TO [public]
GO
