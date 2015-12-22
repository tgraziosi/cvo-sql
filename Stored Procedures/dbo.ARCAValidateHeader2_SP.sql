SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARCAValidateHeader2_SP]	@error_level smallint, 
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





DECLARE @ib_flag	INTEGER			--AAP

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcavh2.cpp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "

	























	
	




	
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


	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20603
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20607

	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN
		INSERT	#account
		SELECT	trx_ctrl_num,
			cash_acct_code,
			date_applied,
			nat_cur_code,
			20603,
			@e_level_act,
			20607,
			@e_level_cur
		FROM	#arvalpyt
		WHERE	void_type != 3
	END

	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20604
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20608

	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN
		INSERT	#account	
		SELECT	a.trx_ctrl_num,
			b.on_acct_code,
			a.date_applied,
			a.nat_cur_code,
			20604,			
			@e_level_act,
			20608,
			@e_level_cur
		FROM	#arvalpyt a, arpymeth b
		WHERE	a.payment_code = b.payment_code
		AND	a.non_ar_flag = 0
	END

	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20605
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20609
	SELECT	@e_level_gain = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20619

	








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
			20605,			
			@e_level_act,
			20609,
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
			20605,			
			@e_level_act,
			20609,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalpdt pdt, araccts ac
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.posting_code = ac.posting_code
		AND	((pdt.amt_disc_taken + pdt.inv_amt_disc_taken) > (0.0) + 0.0000001)
		AND	pyt.non_ar_flag = 0



















		INSERT	#account
		SELECT pyt.trx_ctrl_num,
			ac.writeoff_account,
			pyt.date_applied,
			pdt.inv_cur_code,
			20605,			
			@e_level_act,
			20609,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalpdt pdt, arwrofac ac
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.writeoff_code = ac.writeoff_code
		AND	pdt.wr_off_flag = 1
		AND	pyt.non_ar_flag = 0

		


		SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20606
		SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20610

		IF (@e_level_act + @e_level_cur) > 0 
		BEGIN
			INSERT	#account
			SELECT	pyt.trx_ctrl_num,
				det.gl_acct_code,
				pyt.date_applied,
				pyt.nat_cur_code,
				20606,
				@e_level_act,
				20610,
				@e_level_cur
			FROM	#arvalpyt pyt, #arnonardet_work det
			WHERE	non_ar_flag = 1
			AND	pyt.trx_ctrl_num = det.trx_ctrl_num

		END


	
	SELECT 	@ib_flag = 0
	SELECT 	@ib_flag = ib_flag
	FROM 	glco
if(@ib_flag = 0)
BEGIN

	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20625) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arvcavh2.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same \arvcavh2"
		


		UPDATE 	#arvalpdt
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalpdt
	        SET 	temp_flag = 1
		FROM 	#arvalpdt a, #arvalpyt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		ANd	a.trx_type = b.trx_type
		AND 	a.org_id = b.org_id

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20625, 		b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	0,
			'', 			0
		FROM 	#arvalpdt a, #arvalpyt b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.temp_flag = 0
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
		


		
		INSERT	#account
		SELECT pyt.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.cm_on_acct_code,pyt.org_id),
			pyt.date_applied,
			pyt.nat_cur_code,
			20605,			
			@e_level_act,
			20609,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalpdt pdt, araccts ac
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.posting_code = ac.posting_code
		AND	pyt.payment_type >= 3
		AND	pyt.non_ar_flag = 0

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
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcavh2.cpp" + ", line " + STR( 373, 5 ) + " -- MSG: " + "Validate gain/loss accounts exist"


			CREATE TABLE #g_l_accts
			(
			 trx_ctrl_num varchar(16),
			 nat_cur_code varchar(8),
			 ar_acct_code varchar(32),
			 flag smallint
			)

			INSERT	#g_l_accts (trx_ctrl_num, nat_cur_code, ar_acct_code, flag)
			SELECT	DISTINCT pyt.trx_ctrl_num, pdt.inv_cur_code, dbo.IBAcctMask_fn(ac.ar_acct_code,pyt.org_id),0
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
				20619,
				nat_cur_code,
				"",
				0,
				0.0,
				0,
				trx_ctrl_num,
				0,
				"",
				0
			FROM	#g_l_accts
			WHERE	flag = 0

			DROP TABLE #g_l_accts
		END

	END



	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcavh2.cpp" + ", line " + STR( 424, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCAValidateHeader2_SP] TO [public]
GO
