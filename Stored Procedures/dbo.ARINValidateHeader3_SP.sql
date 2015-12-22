SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARINValidateHeader3_SP]	@error_level	smallint,
						@trx_type	smallint,
						@debug_level	smallint = 0
AS

DECLARE	
	@result	smallint,
	@active_flag	smallint,
	@currency_flag	smallint

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 51, 5 ) + " -- ENTRY: "

	


	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20096 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 59, 5 ) + " -- MSG: " + "Validate that the posting code tax rounding account is populated"
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20096,
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
	WHERE	e_code = 20055
	
	SELECT @currency_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20056

	IF (@active_flag + @currency_flag) > 0 
	BEGIN
		


		INSERT	#account
		SELECT chg.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.ar_acct_code,chg.org_id),
			chg.date_applied,
			chg.nat_cur_code,
			20055,			
			@active_flag,
			20056,
			@currency_flag
		FROM	#arvalchg chg, araccts ac
		WHERE	chg.posting_code = ac.posting_code
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 112, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		


		INSERT	#account
		SELECT chg.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.freight_acct_code,chg.org_id),
			chg.date_applied,
			chg.nat_cur_code,
			20055,			
			@active_flag,
			20056,
			@currency_flag
		FROM	#arvalchg chg, araccts ac
		WHERE	chg.posting_code = ac.posting_code
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 133, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		


		INSERT	#account
		SELECT chg.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.disc_given_acct_code,chg.org_id),
			chg.date_applied,
			chg.nat_cur_code,
			20055,			
			@active_flag,
			20056,
			@currency_flag
		FROM	#arvalchg chg, araccts ac
		WHERE	chg.posting_code = ac.posting_code
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 153, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		


		INSERT	#account
		SELECT chg.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.tax_rounding_acct_code,chg.org_id),
			chg.date_applied,
			chg.nat_cur_code,
			20055,			
			@active_flag,
			20056,
			@currency_flag
		FROM	#arvalchg chg, araccts ac
		WHERE	chg.posting_code = ac.posting_code
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 174, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	


      	SELECT @active_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20091
	
	SELECT @currency_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20092

	IF (@active_flag + @currency_flag) > 0 
	BEGIN
		


		IF @trx_type = 2031
		BEGIN
			INSERT	#account
			SELECT chg.trx_ctrl_num,
				cdt.gl_rev_acct,
				chg.date_applied,
				chg.nat_cur_code,
				20091,			
				@active_flag,
				20092,
				@currency_flag
			FROM	#arvalchg chg, #arvalcdt cdt
			WHERE	chg.trx_ctrl_num = cdt.trx_ctrl_num
			AND	chg.trx_type = cdt.trx_type
			
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 212, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END
		ELSE  
		BEGIN
			


			INSERT	#account
			SELECT chg.trx_ctrl_num,
				rev.rev_acct_code,
				chg.date_applied,
				chg.nat_cur_code,
				20091,			
				@active_flag,
				20092,
				@currency_flag
			FROM	#arvalchg chg, #arvalrev rev
			WHERE	chg.trx_ctrl_num = rev.trx_ctrl_num
			AND	chg.trx_type = rev.trx_type
			
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 236, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END
	END

	


      	SELECT @active_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20093
	
	SELECT @currency_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20094

	IF (@active_flag + @currency_flag) > 0 
	BEGIN
		


		INSERT	#account
		SELECT chg.trx_ctrl_num,
			dbo.IBAcctMask_fn(typ.sales_tax_acct_code, chg.org_id),
			chg.date_applied,
			chg.nat_cur_code,
			20093,			
			@active_flag,
			20094,
			@currency_flag
		FROM	#arvalchg chg, #arvaltax tax, artxtype typ
		WHERE	chg.trx_ctrl_num = tax.trx_ctrl_num
		AND	chg.trx_type = tax.trx_type
		AND	tax.tax_type_code = typ.tax_type_code
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 274, 5 ) + " -- EXIT: "
			RETURN 34563
		END

	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20054 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 285, 5 ) + " -- MSG: " + "Validating that the posting code exists in the posting code table"

		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	araccts a
		WHERE	#arvalchg.posting_code = a.posting_code
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20054,
			posting_code,
			"",
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg
	  	WHERE	temp_flag = 0 
	END


	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20057 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 320, 5 ) + " -- MSG: " + "Validate that the posting code of the invoice is valid for the currency code"

		UPDATE	#arvalchg
		SET	temp_flag = 0

		


		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg a, araccts b
		WHERE	a.posting_code = b.posting_code
		AND	(a.nat_cur_code = b.nat_cur_code OR ( LTRIM(b.nat_cur_code) IS NULL OR LTRIM(b.nat_cur_code) = " " ) )
						
		


		INSERT	#ewerror
		SELECT 2000,
		  	20057,
			posting_code + "--" + nat_cur_code,
			"",
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg 
	  	WHERE	temp_flag = 0
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvh3.cpp" + ", line " + STR( 353, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateHeader3_SP] TO [public]
GO
