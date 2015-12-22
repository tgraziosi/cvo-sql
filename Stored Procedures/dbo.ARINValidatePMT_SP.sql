SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARINValidatePMT_SP]	@error_level	smallint,
					@trx_type	smallint,
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
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinvpmt.sp' + ', line ' + STR( 58, 5 ) + ' -- ENTRY: '

	
 	SELECT @active_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20070
	
	SELECT @currency_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20071

	IF (@active_flag + @currency_flag) > 0 
	BEGIN
		
	 	INSERT	#account
		SELECT	tmp.trx_ctrl_num,
			tmp.cash_acct_code,
			chg.date_applied,
			chg.nat_cur_code,
			20070,
			@active_flag,
			20071,
			@currency_flag
		FROM	#arvaltmp tmp, #arvalchg chg
		WHERE	chg.trx_ctrl_num = tmp.trx_ctrl_num
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinvpmt.sp' + ', line ' + STR( 90, 5 ) + ' -- EXIT: '
			RETURN 34563
		END
	END
	
	
 	SELECT @active_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20072
	
	SELECT @currency_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20073

	IF (@active_flag + @currency_flag) > 0 
	BEGIN
		
		INSERT	#account
		SELECT	tmp.trx_ctrl_num,
			meth.on_acct_code,
			chg.date_applied,
			chg.nat_cur_code,
			20072,
			@active_flag,
			20073,
			@currency_flag
		FROM	#arvaltmp tmp, arpymeth meth, #arvalchg chg
		WHERE	tmp.trx_ctrl_num = chg.trx_ctrl_num
		AND	tmp.payment_code = meth.payment_code
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinvpmt.sp' + ', line ' + STR( 124, 5 ) + ' -- EXIT: '
			RETURN 34563
		END
	END
	
	
	
	SELECT	@min_date = MIN(period_start_date),
		@max_date = MAX(period_end_date)
	FROM	glprd
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20074 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20074,
			'',			'',			date_doc,
			0.0,			3,		trx_ctrl_num,
			0,			'',			0				
		FROM	#arvaltmp
		WHERE	date_doc > @max_date
		OR	date_doc < @min_date
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinvpmt.sp' + ', line ' + STR( 157, 5 ) + ' -- EXIT: '
			RETURN 34563
		END
	END

	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20097  ) >= @error_level
	BEGIN

		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinvpmt.sp' + ', line ' + STR( 165, 5 ) + ' -- ENTRY: '


		UPDATE	#arvalchg
		SET	temp_flag = 0

		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg a, #arvaltmp b, apcash c
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	c.cash_acct_code = b.cash_acct_code
		AND	a.org_id <> c.org_id					
		AND	b.amt_payment <> 0
		

		INSERT	#ewerror
		SELECT 2000,
		 	20097,
			doc_ctrl_num,
			'',
			0,
			0.0,
			1,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg 
	  	WHERE	temp_flag = 1


		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinvpmt.sp' + ', line ' + STR( 170, 5 ) + ' -- EXIT: '
			RETURN 34563
		END
	END


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinvpmt.sp' + ', line ' + STR( 163, 5 ) + ' -- EXIT: '
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidatePMT_SP] TO [public]
GO
