SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCMValidateLineItem_SP]	@error_level	smallint,
						@debug_level	smallint = 0
AS

DECLARE @ib_flag	INTEGER			--AAP

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmvli.cpp' + ', line ' + STR( 55, 5 ) + ' -- ENTRY: '
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20251  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20251,
			'',			'',			sequence_id,
			0.0,			4,		trx_ctrl_num,
			sequence_id,		'',			0				
		FROM	#arvalcdt
		WHERE	sequence_id <= 0
	END
	


	
	SELECT 	@ib_flag = 0
	SELECT 	@ib_flag = ib_flag
	FROM 	glco

if(@ib_flag > 0)
BEGIN
	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20269 ) >= @error_level
	BEGIN
		UPDATE 	#arvalcdt
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalcdt
		SET 	temp_flag2 = 1
		FROM 	#arvalchg a, #arvalcdt b, OrganizationOrganizationDef ood
		WHERE 	b.trx_ctrl_num = a.trx_ctrl_num
		AND	a.org_id = ood.controlling_org_id
		AND 	b.org_id = ood.detail_org_id
		AND 	b.gl_rev_acct LIKE ood.account_mask			

		INSERT INTO #ewerror
		(   module_id,      	err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 2000, 20269, b.gl_rev_acct,
			b.org_id, user_id, 0.0,
			0, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalcdt b, #arvalchg a
		WHERE 	b.trx_ctrl_num = a.trx_ctrl_num
		AND	b.sequence_id > -1
		AND 	a.interbranch_flag = 1
		AND 	b.temp_flag2 = 0
		AND	a.org_id <> b.org_id
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20271 ) >= @error_level
	BEGIN

		UPDATE 	#arvalcdt
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalcdt
		SET 	temp_flag2 = 1
		FROM 	#arvalcdt a, Organization o
		WHERE 	a.org_id = o.organization_id
		AND 	o.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20271, b.org_id,
			b.org_id, '', 0.0,
			0, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalchg a, #arvalcdt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND 	b.temp_flag2 = 0
	END

	



	IF (SELECT e_level FROM aredterr WHERE e_code = 20272) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmvli.cpp' + ', line ' + STR( 126, 5 ) + ' -- MSG: ' + 'Validate account code for organization \arcmvli'

		


		UPDATE 	#arvalcdt
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalcdt
	        SET 	temp_flag = 1
		FROM 	#arvalcdt a
		WHERE   dbo.IBOrgbyAcct_fn(a.gl_rev_acct)  = a.org_id 

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20272, 		a.gl_rev_acct,
			a.org_id, 		0, 			0.0,
			0, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalcdt a
		WHERE 	a.temp_flag = 0
	END

END	--AAP

ELSE
BEGIN
	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20273) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmvli.cpp' + ', line ' + STR( 126, 5 ) + ' -- MSG: ' + 'Validate all organizations are the same \arcmvli'
		


		UPDATE 	#arvalcdt
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalcdt
	        SET 	temp_flag = 1
		FROM 	#arvalcdt a, #arvalchg b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		ANd	a.trx_type = b.trx_type
		AND 	a.org_id = b.org_id

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20273, 		b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			0, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalcdt a, #arvalchg b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.temp_flag = 0
	END	
END

	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20252  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20252,
			'',			'',			0,
			qty_returned,		1,		trx_ctrl_num,
			sequence_id,		'',			0				
		FROM	#arvalcdt
		WHERE	((qty_returned) <= (0.0) + 0.0000001)
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20253  ) >= @error_level
	BEGIN
		UPDATE	#arvalcdt
		SET	temp_flag = 0
		
		UPDATE	#arvalcdt
		SET	temp_flag = 1
		FROM	#arvalcdt cdt, artax tax
		WHERE	cdt.tax_code = tax.tax_code
	
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20253,
			tax_code,		'',			0,
			0.0,			0,		trx_ctrl_num,
			sequence_id,		'',			0				
		FROM	#arvalcdt
		WHERE	temp_flag = 0
	END
	
		


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20275 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmvli.cpp' + ', line ' + STR( 302, 5 ) + ' -- MSG: ' + 'Validate the detail line item tax code is valid for tax_connect'



		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20275,
			a.tax_code,			'',
			0,				0.0,
			0,			a.trx_ctrl_num,
			a.sequence_id,			'',
			0
		FROM #arvalchg ar, #arvalcdt a, artax tax, artax ta	
	  	WHERE ar.trx_ctrl_num = a.trx_ctrl_num AND ar.trx_type = a.trx_type
		AND a.tax_code = tax.tax_code AND ar.tax_code = ta.tax_code 
		AND tax.tax_connect_flag != ta.tax_connect_flag
		
	END




	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20258  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   		err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20258,
			'',			'',			0,
			unit_price,		1,		trx_ctrl_num,
			sequence_id,		'',			0				
		FROM	#arvalcdt
		WHERE	((unit_price) <= (0.0) + 0.0000001)
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20259  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   		err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20259,
			'',			'',			0,
			unit_price,		1,		trx_ctrl_num,
			sequence_id,		'',			0				
		FROM	#arvalcdt
		WHERE	(ABS((unit_price)-(0.0)) < 0.0000001)		   	
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20260  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20260,
			'',			'',			0,
			discount_amt,		1,		trx_ctrl_num,
			sequence_id,		'',			0				
		FROM	#arvalcdt
		WHERE	((discount_amt) < (0.0) - 0.0000001)		   	
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20261  ) >= @error_level
	BEGIN					    
	
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg chg, #arvalcdt cdt
		WHERE	chg.trx_ctrl_num = cdt.trx_ctrl_num
		AND	chg.trx_type = cdt.trx_type
	
		INSERT	#ewerror
		(	module_id,   		err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20261,
			doc_ctrl_num,		'',			0,
			0.0,			0,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20262  ) >= @error_level
	BEGIN					    
	
		INSERT	#ewerror
		(	module_id,   		err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20262,
			'',			'',			0,
			(SIGN(cdt.unit_price*cdt.qty_returned-cdt.discount_amt) * ROUND(ABS(cdt.unit_price*cdt.qty_returned-cdt.discount_amt) + 0.0000001, gl.curr_precision)),			
						1,		cdt.trx_ctrl_num,
			cdt.sequence_id,	'',			0				
		FROM	#arvalcdt cdt, #arvalchg chg, glcurr_vw gl
		WHERE	cdt.trx_ctrl_num = chg.trx_ctrl_num
		AND	cdt.trx_type = chg.trx_type
		AND	chg.nat_cur_code = gl.currency_code
		AND	
(ABS((cdt.extended_price)-((SIGN(cdt.unit_price*qty_returned-discount_amt) * ROUND(ABS(cdt.unit_price*qty_returned-discount_amt) + 0.0000001, gl.curr_precision)))) > 0.0000001)
	END
	
	




	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20263  ) >= @error_level
	BEGIN					    
	
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20263,
			'',			'',			0,
			qty_prev_returned, 	1,		trx_ctrl_num,
			sequence_id,		'',			0				
		FROM	#arvalcdt
		WHERE	((qty_prev_returned) >= (qty_shipped) - 0.0000001)
		AND	((qty_shipped) > (0.0) + 0.0000001)
	END
	
	




	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20264  ) >= @error_level
	BEGIN					    
	
		INSERT	#ewerror
		      (module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20264,
			'',			'',			0,
			qty_prev_returned + qty_returned, 
						1,		trx_ctrl_num,
			sequence_id,		'',			0				
		FROM	#arvalcdt
		WHERE	((qty_prev_returned+qty_returned) > (qty_shipped) + 0.0000001)
		AND	((qty_shipped) > (0.0) + 0.0000001)
	END


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmvli.cpp' + ', line ' + STR( 506, 5 ) + ' -- EXIT: '
END
GO
GRANT EXECUTE ON  [dbo].[ARCMValidateLineItem_SP] TO [public]
GO
