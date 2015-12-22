SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARCRValidateHeader2_SP]	@error_level smallint, 
						@debug_level smallint = 0
AS

DECLARE	
	@result	smallint,
	@e_level	smallint,
	@e_level_act	smallint,
	@e_level_cur	smallint,
	@e_level_gain	smallint,



	@active_flag	smallint,
	@currency_flag	smallint






BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvh2.cpp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

	























	
	




	
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


	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20405
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20409

	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN
		INSERT	#account
		SELECT	trx_ctrl_num,
			cash_acct_code,
			date_applied,
			nat_cur_code,
			20405,
			@e_level_act,
			20409,
			@e_level_cur
		FROM	#arvalpyt
		WHERE	payment_type < 3
	END

	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20406
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20410

	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN
		INSERT	#account	
		SELECT	a.trx_ctrl_num,
			b.on_acct_code,
			a.date_applied,
			a.nat_cur_code,
			20406,			
			@e_level_act,
			20410,
			@e_level_cur
		FROM	#arvalpyt a, arpymeth b
		WHERE	a.payment_code = b.payment_code
		AND	a.non_ar_flag = 0
	END

	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20407
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20411
	SELECT	@e_level_gain = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20413

	








	IF (@e_level_act + @e_level_cur + @e_level_gain) > 0 
	BEGIN
		UPDATE	#arvalpdt
		SET	posting_code = trx.posting_code
		FROM	#arvalpdt, artrx trx
		WHERE	#arvalpdt.apply_to_num = trx.doc_ctrl_num
		AND	#arvalpdt.apply_trx_type = trx.trx_type
		
	END


	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN
		INSERT	#account
		SELECT pyt.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.ar_acct_code,pyt.org_id),
			pyt.date_applied,
			pdt.inv_cur_code,
			20407,			
			@e_level_act,
			20411,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalpdt pdt, araccts ac
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.posting_code = ac.posting_code
		AND	pyt.non_ar_flag = 0

		INSERT	#account
		SELECT pyt.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.disc_taken_acct_code,pyt.org_id),
			pyt.date_applied,
			pdt.inv_cur_code,
			20407,			
			@e_level_act,
			20411,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalpdt pdt, araccts ac
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.posting_code = ac.posting_code
		AND	((pdt.amt_disc_taken + pdt.inv_amt_disc_taken) > (0.0) + 0.0000001)
		AND	pyt.non_ar_flag = 0

		INSERT	#account
		SELECT pyt.trx_ctrl_num,
			dbo.IBAcctMask_fn(wro.writeoff_account,pyt.org_id),
			pyt.date_applied,
			pdt.inv_cur_code,
			20407,			
			@e_level_act,
			20411,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalpdt pdt, araccts ac, arcust cus, arwrofac wro
		WHERE	pyt.trx_ctrl_num  = pdt.trx_ctrl_num
		AND	pdt.posting_code  = ac.posting_code
		AND     pyt.customer_code = cus.customer_code
		AND     cus.writeoff_code = wro.writeoff_code
		AND     cus.address_type  = 0
		AND	pdt.wr_off_flag   = 1
		AND	pyt.non_ar_flag   = 0

		INSERT	#account
		SELECT pyt.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.cm_on_acct_code,pyt.org_id),
			pyt.date_applied,
			pyt.nat_cur_code,
			20407,			
			@e_level_act,
			20411,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalpdt pdt, araccts ac
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.posting_code = ac.posting_code
		AND	pyt.payment_type >= 3
		AND	pyt.non_ar_flag = 0

	END

	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20408
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20412

	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN














		


		


		INSERT	#account
		SELECT  det.trx_ctrl_num,
			det.gl_acct_code,
			pyt.date_applied,
			pyt.nat_cur_code,
			20408,			
			@e_level_act,
			20412,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalnonardet det
		WHERE	pyt.trx_ctrl_num = det.trx_ctrl_num
		AND	pyt.non_ar_flag = 1

		


		


	      	SELECT @active_flag = SIGN(SIGN(e_level-@error_level)+1)
		FROM	aredterr
		WHERE	e_code = 20093
		
		SELECT @currency_flag = SIGN(SIGN(e_level-@error_level)+1)
		FROM	aredterr
		WHERE	e_code = 20094
	
		IF (@active_flag + @currency_flag) > 0 
		BEGIN
			


			INSERT	#account
			SELECT  pyt.trx_ctrl_num,
				dbo.IBAcctMask_fn(typ.sales_tax_acct_code, pyt.org_id),
				pyt.date_applied,
				pyt.nat_cur_code,
				20093,			
				@active_flag,
				20094,
				@currency_flag
			FROM	#arvalpyt pyt, #arvaltax tax, artxtype typ
			WHERE	pyt.trx_ctrl_num  = tax.trx_ctrl_num
			AND	pyt.trx_type      = tax.trx_type
			AND	tax.tax_type_code = typ.tax_type_code
			AND	pyt.non_ar_flag   = 1
		END
		


	END
	

	



	EXEC @result = ARValidateACCounT_SP	@debug_level
	IF( @result != 0 )
	BEGIN
		RETURN @result
	END
	DROP TABLE #account
	
	


	IF ((SELECT mc_flag FROM arco) = 1)
	BEGIN
		IF @e_level_gain = 1
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvh2.cpp" + ", line " + STR( 315, 5 ) + " -- MSG: " + "Validate gain/loss accounts exist"


			CREATE TABLE #g_l_accts
			(
			 trx_ctrl_num 	varchar(16),
			 source_trx_ctrl_num	varchar(16),
			 nat_cur_code 	varchar(8),
			 ar_acct_code 	varchar(32),
			 flag 			smallint
			)

			INSERT	#g_l_accts (	trx_ctrl_num, source_trx_ctrl_num,
						nat_cur_code, ar_acct_code, flag)
			SELECT	DISTINCT 	pyt.trx_ctrl_num, ISNULL(pyt.source_trx_ctrl_num, " "),
						pdt.inv_cur_code, dbo.IBAcctMask_fn(ac.ar_acct_code, pyt.org_id),0
			FROM	#arvalpdt pdt, #arvalpyt pyt, araccts ac
			WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pdt.posting_code = ac.posting_code
			AND	(pdt.inv_cur_code != pyt.nat_cur_code
				OR (ABS((pdt.gain_home)-(0.0)) > 0.0000001)
					OR (ABS((pdt.gain_oper)-(0.0)) > 0.0000001))

			UPDATE #g_l_accts
			SET flag = 1
			FROM CVO_Control..mccocdt a, #g_l_accts b, glco c
			WHERE a.company_code = c.company_code
			AND b.ar_acct_code like a.acct_mask
			AND a.currency_code = b.nat_cur_code


			INSERT	#ewerror
			SELECT 2000,
				20413,
				nat_cur_code,
				"",
				0,
				0.0,
				0,
				trx_ctrl_num,
				0,
				source_trx_ctrl_num,
				0
			FROM	#g_l_accts
			WHERE	flag = 0

			DROP TABLE #g_l_accts
		END

	END

	



	IF ((SELECT bb_flag FROM arco) = 1)
	BEGIN
	
		IF (SELECT e_level FROM aredterr WHERE e_code = 20426) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvh2.cpp" + ", line " + STR( 375, 5 ) + " -- MSG: " + "Validate payment currency matches cash account currency"

			/*UPDATE	#arvalpyt
			SET	temp_flag = 0
			
			UPDATE #arvalpyt
			SET	temp_flag = 1
			WHERE	payment_type > 1
			
			UPDATE	#arvalpyt
			SET	temp_flag = 1
			FROM	apcash ap
			WHERE	#arvalpyt.payment_type = 1
			AND	#arvalpyt.cash_acct_code = ap.cash_acct_code
			AND	#arvalpyt.nat_cur_code = ap.nat_cur_code
			

			INSERT #ewerror
			SELECT	2000,
				20426,
				cash_acct_code,
				"",
				0,
				0.0,
				0,
				trx_ctrl_num,
				0,
				ISNULL(source_trx_ctrl_num, ""),
				0
			FROM	#arvalpyt 
			WHERE	temp_flag = 0*/
			
			INSERT #ewerror
			SELECT	2000,
				20426,
				cash_acct_code,
				"",
				0,
				0.0,
				0,
				trx_ctrl_num,
				0,
				ISNULL(source_trx_ctrl_num, ""),
				0
			FROM	#arvalpyt #arvalpyt
			WHERE	#arvalpyt.payment_type <= 1
			AND NOT EXISTS (select 1 from apcash ap where #arvalpyt.payment_type = 1
			AND	#arvalpyt.cash_acct_code = ap.cash_acct_code
			AND	#arvalpyt.nat_cur_code = ap.nat_cur_code )
		END
	
	END
	
	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvh2.cpp" + ", line " + STR( 411, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCRValidateHeader2_SP] TO [public]
GO
