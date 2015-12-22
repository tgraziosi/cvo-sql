SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCMValidateHeader4_SP]	@error_level	smallint,
					@debug_level	smallint = 0
AS

DECLARE
	@active_flag		smallint,
	@currency_flag	smallint,
	@min_date		int,
	@max_date		int,
	@sys_date		int,
	@date_applied_flag	smallint,
	@date_doc_flag	smallint,
	@result		int

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh4.cpp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20224  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20224,
			"",			"",			chg.date_applied,
			0.0,			3,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg, arco
		WHERE	chg.date_applied > arco.period_end_date
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20225  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20225,
			"",			"",			chg.date_applied,
			0.0,			3,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg, arco, glprd prd
		WHERE	arco.period_end_date = prd.period_end_date
		AND	chg.date_applied < prd.period_start_date
	END
	
	



	SELECT @date_applied_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20226
	
	SELECT @date_doc_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20228
	
	IF (@date_applied_flag+@date_doc_flag) >= 1
	BEGIN
		SELECT @min_date = MIN(period_start_date), 
			@max_date = MAX(period_end_date)
		FROM	glprd
	
		


		IF ( @date_applied_flag = 1 )
			INSERT	#ewerror
			(	module_id,   					err_code,		
				info1,			info2,			infoint,
				infofloat,		flag1,			trx_ctrl_num,
				sequence_id,		source_ctrl_num,	extra
			)
			SELECT 2000,			20226,
				"",			"",			date_applied,
				0.0,			3,		trx_ctrl_num,
				0,			"",			0				
			FROM	#arvalchg
			WHERE	date_applied > @max_date
			OR	date_applied < @min_date
		
		


		IF ( @date_doc_flag = 1 )
			INSERT	#ewerror
			(	module_id,   					err_code,		
				info1,			info2,			infoint,
				infofloat,		flag1,			trx_ctrl_num,
				sequence_id,		source_ctrl_num,	extra
			)
			SELECT 2000,			20228,
				"",			"",			date_doc,
				0.0,			3,		trx_ctrl_num,
				0,			"",			0				
			FROM	#arvalchg
			WHERE	date_applied > @max_date
			OR	date_applied < @min_date
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20227  ) >= @error_level
	BEGIN
		EXEC appdate_sp @sys_date OUTPUT
		
		SELECT	@min_date = @sys_date - date_range_verify,
			@max_date = @sys_date + date_range_verify
		FROM	arco
		
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20227,
			"",			"",			date_applied,
			0.0,			3,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	date_applied > @max_date
		OR	date_applied < @min_date
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20236  ) >= @error_level
	BEGIN
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg chg, araccts acct
		WHERE	chg.posting_code = acct.posting_code
	
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20236,
			posting_code,		"",			0,
			0.0,			0,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END
	
	


	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20239  ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id,   					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20239,
			chg.posting_code,	"",			0,
			0.0,			0,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg, araccts acct
		WHERE	chg.posting_code = acct.posting_code
		AND	( LTRIM(acct.nat_cur_code) IS NOT NULL AND LTRIM(acct.nat_cur_code) != " " )
		AND	chg.nat_cur_code != acct.nat_cur_code
	END
	
	


	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20267 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh4.cpp" + ", line " + STR( 243, 5 ) + " -- MSG: " + "Validate that the posting code tax rounding account is populated"
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20267,
			chg.posting_code,
			"",
			0,
			0.0,
			0,
			chg.trx_ctrl_num,
			0,
			ISNULL(chg.source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg chg, araccts acct
	  	WHERE	chg.posting_code = acct.posting_code
	  	AND	( LTRIM(acct.tax_rounding_acct_code) IS NULL OR LTRIM(acct.tax_rounding_acct_code) = " " ) 
	END
	

      	SELECT @active_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20237
	
	SELECT @currency_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20238

	IF (@active_flag + @currency_flag) > 0 
	BEGIN
		
CREATE TABLE #account (
				trx_ctrl_num	varchar(16),
				account_code	varchar(32),
				date_applied	int,
				currency_code	varchar(8),
				err_code_act	int,
				active_check	smallint,
				err_code_cur	int,
				cur_check	smallint
					)

		
		


	   	INSERT	#account
		SELECT	chg.trx_ctrl_num,
			cdt.gl_rev_acct,
			chg.date_applied,
			chg.nat_cur_code,
			20237,
			@active_flag,
			20238,
			@currency_flag
		FROM	#arvalchg chg, #arvalcdt cdt
		WHERE	chg.trx_ctrl_num = cdt.trx_ctrl_num
		
		


		INSERT	#account
		SELECT	trx_ctrl_num,
			dbo.IBAcctMask_fn(cm_on_acct_code,chg.org_id),	
			date_applied,
			chg.nat_cur_code,
			20237,
			@active_flag,
			20238,
			@currency_flag
		FROM	#arvalchg chg, araccts acct
		WHERE	chg.posting_code = acct.posting_code
		
		


		INSERT	#account
		SELECT	trx_ctrl_num,
			dbo.IBAcctMask_fn(freight_acct_code,chg.org_id),
			date_applied,
			chg.nat_cur_code,
			20237,
			@active_flag,
			20238,
			@currency_flag
		FROM	#arvalchg chg, araccts acct
		WHERE	chg.posting_code = acct.posting_code
		
		


		INSERT	#account
		SELECT	chg.trx_ctrl_num,
			dbo.IBAcctMask_fn(arwo.writeoff_account,chg.org_id),
			chg.date_applied,
			chg.nat_cur_code,
			20237,
			@active_flag,
			20238,
			@currency_flag
		FROM	#arvalchg chg, arwrofac arwo, arinpchg arin
		WHERE	chg.trx_ctrl_num = arin.trx_ctrl_num
		AND	arin.writeoff_code = arwo.writeoff_code
		
		


		INSERT	#account
		SELECT	trx_ctrl_num,
			dbo.IBAcctMask_fn(disc_taken_acct_code,chg.org_id),
			date_applied,
			chg.nat_cur_code,
			20237,
			@active_flag,
			20238,
			@currency_flag
		FROM	#arvalchg chg, araccts acct
		WHERE	chg.posting_code = acct.posting_code
		
		


		INSERT	#account
		SELECT	trx_ctrl_num,
			dbo.IBAcctMask_fn(disc_given_acct_code,chg.org_id),
			date_applied,
			chg.nat_cur_code,
			20237,
			@active_flag,
			20238,
			@currency_flag
		FROM	#arvalchg chg, araccts acct
		WHERE	chg.posting_code = acct.posting_code
		
		


		INSERT	#account
		SELECT	trx_ctrl_num,
			dbo.IBAcctMask_fn(tax_rounding_acct_code,chg.org_id),
			date_applied,
			chg.nat_cur_code,
			20237,
			@active_flag,
			20238,
			@currency_flag
		FROM	#arvalchg chg, araccts acct
		WHERE	chg.posting_code = acct.posting_code
		
		


		INSERT	#account
		SELECT	chg.trx_ctrl_num,
			dbo.IBAcctMask_fn(sales_tax_acct_code, chg.org_id),
			chg.date_applied,
			chg.nat_cur_code,
			20237,
			@active_flag,
			20238,
			@currency_flag
		FROM	#arvalchg chg, #arvaltax tax, artxtype type
		WHERE	chg.trx_ctrl_num = tax.trx_ctrl_num
		AND	tax.tax_type_code = type.tax_type_code
		
		EXEC @result = ARValidateACCounT_SP	@debug_level
		IF( @result != 0 )
		BEGIN
			RETURN @result
		END	

		DROP TABLE #account
	
	END
		
	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvh4.cpp" + ", line " + STR( 411, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCMValidateHeader4_SP] TO [public]
GO
