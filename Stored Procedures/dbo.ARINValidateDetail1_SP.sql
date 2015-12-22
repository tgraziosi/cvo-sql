SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARINValidateDetail1_SP]	@error_level	smallint,
					@trx_type	smallint,
					@debug_level	smallint = 0
AS

DECLARE	
	@result	smallint

DECLARE @ib_flag	INTEGER			--AAP

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 60, 5 ) + ' -- ENTRY: '
	
	

	
	SELECT 	@ib_flag = 0
	SELECT 	@ib_flag = ib_flag
	FROM 	glco

if(@ib_flag > 0)
BEGIN
	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20099 ) >= @error_level
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
		SELECT 2000, 20099, b.gl_rev_acct,
			b.org_id, user_id, 0.0,
			1, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalcdt b, #arvalchg a
		WHERE 	b.trx_ctrl_num = a.trx_ctrl_num
		AND	b.sequence_id > -1
		AND 	a.interbranch_flag = 1
		AND 	b.temp_flag2 = 0
		AND	a.org_id <> b.org_id 
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20101 ) >= @error_level
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
		SELECT 2000, 20101, b.org_id,
			b.org_id, '', 0.0,
			1, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalchg a, #arvalcdt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND 	b.temp_flag2 = 0
	END

	



	IF (SELECT e_level FROM aredterr WHERE e_code = 20102) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 126, 5 ) + ' -- MSG: ' + 'Validate account code for organization \arinpcdt'

		


		UPDATE 	#arvalcdt
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalcdt
	        SET 	temp_flag = 1
		FROM 	#arvalcdt a
		WHERE  dbo.IBOrgbyAcct_fn(a.gl_rev_acct)  = a.org_id 

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20102, 		a.gl_rev_acct,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalcdt a
		WHERE 	a.temp_flag = 0
	END

	IF @trx_type = 2021
	BEGIN
	


		


		IF ( SELECT e_level FROM aredterr WHERE e_code = 20099 ) >= @error_level
		BEGIN
			UPDATE 	#arvalrev
		        SET 	temp_flag = 0
	
			UPDATE 	#arvalrev
			SET 	temp_flag = 1
			FROM 	#arvalchg a, #arvalrev b, OrganizationOrganizationDef ood
			WHERE 	b.trx_ctrl_num = a.trx_ctrl_num
			AND	a.org_id = ood.controlling_org_id
			AND 	b.org_id = ood.detail_org_id
			AND 	b.rev_acct_code LIKE ood.account_mask			
	
			INSERT INTO #ewerror
			(   module_id,      	err_code,       info1,
				info2,          infoint,        infofloat,
				flag1,          trx_ctrl_num,   sequence_id,
				source_ctrl_num,	extra
			)
			SELECT 2000, 20099, b.rev_acct_code,
				b.org_id, user_id, 0.0,
				0, b.trx_ctrl_num, b.sequence_id,
				b.trx_ctrl_num, 0
			FROM 	#arvalrev b, #arvalchg a
			WHERE 	b.trx_ctrl_num = a.trx_ctrl_num
			AND	b.sequence_id > -1
			AND 	a.interbranch_flag = 1
			AND 	b.temp_flag = 0
			AND	a.org_id <> b.org_id 

		END
	
		


		IF ( SELECT e_level FROM aredterr WHERE e_code = 20101 ) >= @error_level
		BEGIN
	
			UPDATE 	#arvalrev
		        SET 	temp_flag = 0
	
			UPDATE 	#arvalrev
			SET 	temp_flag = 1
			FROM 	#arvalrev a, Organization o
			WHERE 	a.org_id = o.organization_id
			AND 	o.active_flag = 1
	
			INSERT INTO #ewerror
			(       module_id,      err_code,       info1,
				info2,          infoint,        infofloat,
				flag1,          trx_ctrl_num,   sequence_id,
				source_ctrl_num,extra
			)
			SELECT 2000, 20101, b.org_id,
				b.org_id, '', 0.0,
				0, b.trx_ctrl_num, b.sequence_id,
				b.trx_ctrl_num, 0
			FROM 	#arvalchg a, #arvalrev b
			WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
			AND 	b.temp_flag = 0
		END
		



		IF (SELECT e_level FROM aredterr WHERE e_code = 20102) >= @error_level
		BEGIN
			


			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 126, 5 ) + ' -- MSG: ' + 'Validate account code for organization \arinpcdt'
	
			


			UPDATE 	#arvalrev
		        SET 	temp_flag = 0
	
			



			UPDATE 	#arvalrev
		        SET 	temp_flag = 1
			FROM 	#arvalrev a
			WHERE  dbo.IBOrgbyAcct_fn(a.rev_acct_code)  = a.org_id 

			




			INSERT INTO #ewerror
			(       module_id,      	err_code,       	info1,
				info2,          	infoint,        	infofloat,
				flag1,          	trx_ctrl_num,   	sequence_id,
				source_ctrl_num,	extra
			)
			SELECT 	2000, 20102, 		a.rev_acct_code,
				a.org_id, 		0, 			0.0,
				0, 			a.trx_ctrl_num, 	a.sequence_id,
				'', 			0
			FROM 	#arvalrev a
			WHERE 	a.temp_flag = 0
		END	


	END	--AAP end of  IF @trx_type = 2021

END	--AAP end of  if (@ib_flag > 0)

ELSE
BEGIN
	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20103) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 126, 5 ) + ' -- MSG: ' + 'Validate all organizations are the same \arinvd1'
		


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
		SELECT 	2000, 			20103, 			b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 		0.0,
			0, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalcdt a, #arvalchg b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.temp_flag = 0
	END	--END of e_code = 20103 for Invoice
	IF @trx_type = 2021
	BEGIN
	


		IF (SELECT e_level FROM aredterr WHERE e_code = 20103) >= @error_level
		BEGIN
			


			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 126, 5 ) + ' -- MSG: ' + 'Validate all organizations are the same \arinvd1'

			


			UPDATE 	#arvalrev
		        SET 	temp_flag = 0
	
			



			UPDATE 	#arvalrev
		        SET 	temp_flag = 1
			FROM 	#arvalrev a, #arvalchg b
			WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
			ANd	a.trx_type = b.trx_type
			AND 	a.org_id = b.org_id
	
			




			INSERT INTO #ewerror
			(       module_id,      	err_code,       	info1,
				info2,          	infoint,        	infofloat,
				flag1,          	trx_ctrl_num,   	sequence_id,
				source_ctrl_num,	extra
			)
			SELECT 	2000,20103, 			b.org_id +'-'+ a.org_id,
				a.org_id, 		0, 		0.0,
				0, 			a.trx_ctrl_num, 	a.sequence_id,
				'', 			0
			FROM 	#arvalrev a, #arvalchg b
			WHERE	a.trx_ctrl_num = b.trx_ctrl_num
			AND	a.temp_flag = 0
		END --AAP end of  IF @trx_type = 2021
	END
END

	




	IF @trx_type = 2021
	BEGIN

		RETURN 0
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 406, 5 ) + ' -- EXIT: '

	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20075 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 415, 5 ) + ' -- MSG: ' + 'Validate that the qty ordered is positive'
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20075,
			'',			   	'',
			0,				qty_ordered,
			1,			trx_ctrl_num,
			sequence_id,			'',
			0		
		FROM 	#arvalcdt
	  	WHERE 	((qty_ordered) <= (0.0) + 0.0000001)
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20076 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 444, 5 ) + ' -- MSG: ' + 'Validate that the qty ordered is positive'
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20076,
			'',				'',
			0,				qty_shipped,
			1,			trx_ctrl_num,
			sequence_id,			'',
			0
		FROM 	#arvalcdt
	  	WHERE 	((qty_shipped) <= (0.0) + 0.0000001)
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20078 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 473, 5 ) + ' -- MSG: ' + 'Validate the detail line item tax code exists in the tax table'
		
		UPDATE	#arvalcdt
		SET	temp_flag = 0
		
		UPDATE	#arvalcdt
		SET	temp_flag = 1
		FROM	artax a
		WHERE	#arvalcdt.tax_code = a.tax_code
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20078,
			tax_code,			'',
			0,				0.0,
			0,			trx_ctrl_num,
			sequence_id,			'',
			0
		FROM	#arvalcdt
	  	WHERE	temp_flag = 0 
		
	END
	
	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20110 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 511, 5 ) + ' -- MSG: ' + 'Validate the detail line item tax code is valid for tax_connect'
	
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20110,
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

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20083 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 547, 5 ) + ' -- MSG: ' + 'Validate that the unit price is positive'
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20083,
			'',				'',
			0,				unit_price,
			1,			trx_ctrl_num,
			sequence_id,			'',
			0
		FROM 	#arvalcdt 
	  	WHERE 	((unit_price) <= (0.0) + 0.0000001)
	END


	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20084 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 577, 5 ) + ' -- MSG: ' + 'Check if the unit price is zero'
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20084,
			'',				'',
			0,				unit_price,
			1,			trx_ctrl_num,
			sequence_id,			'',
			0
		FROM 	#arvalcdt 
	  	WHERE 	(ABS((unit_price)-(0.0)) < 0.0000001)
	END


	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20085 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 607, 5 ) + ' -- MSG: ' + 'Validate that the detail line item discount amt is positive'
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20085,
			'',				'',
			0,				discount_amt,
			1,			trx_ctrl_num,
			sequence_id,			'',
			0
		FROM 	#arvalcdt 
	  	WHERE 	((discount_amt) < (0.0) - 0.0000001)
	END
	
	
	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20086 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 637, 5 ) + ' -- MSG: ' + 'Validate that there are line item details for this transaction'
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalcdt a
		WHERE	#arvalchg.trx_ctrl_num = a.trx_ctrl_num
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20086,
			doc_ctrl_num,			'',
			0,				0.0,
			0,			trx_ctrl_num,
			0,			'',
			0		
		FROM	#arvalchg 
	  	WHERE	temp_flag = 0 
	END


	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20087 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 675, 5 ) + ' -- MSG: ' + 'Validate that the extended price is zero'
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20087,
			'',				'',
			0,				extended_price,
			1,			trx_ctrl_num,
			sequence_id,			'',
			0
		FROM 	#arvalcdt 
	  	WHERE 	(ABS((extended_price)-(0.0)) < 0.0000001)
	END


	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20088 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 705, 5 ) + ' -- MSG: ' + 'Validate that the sequence_id is positive'
		
		


		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,  	20088,
			'',				'',
			sequence_id,			0.0,
			5,			trx_ctrl_num,
			0,				'',
			0
		FROM 	#arvalcdt 
	  	WHERE 	sequence_id < 0
	END

	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvd1.cpp' + ', line ' + STR( 730, 5 ) + ' -- EXIT: '
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateDetail1_SP] TO [public]
GO
