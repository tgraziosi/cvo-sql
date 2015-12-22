SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARINEditHold_SP]	@put_on_hold smallint,
						@debug_level smallint
AS

DECLARE	@trx_ctrl_num		varchar(16),
		@trx_type		smallint,
		@home_curr_precision	smallint,
		@oper_curr_precision	smallint

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arineh.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "
	
	CREATE TABLE #temp_batchcodes
	(
		batch_code	varchar(8)
	)
	
	
	UPDATE	#arvalchg
	SET	temp_flag = 0
	
	UPDATE	#arvalchg
	SET	temp_flag = 1
	FROM	#arvalchg chg, #ewerror werr, aredterr err
	WHERE	chg.trx_ctrl_num = werr.trx_ctrl_num
	AND	werr.err_code = err.e_code
	AND	err.e_level >= 3	

	IF (@put_on_hold = 1)
	BEGIN
		
		INSERT #temp_batchcodes(batch_code)
		SELECT DISTINCT chg.batch_code
		FROM #arvalchg chg, arco
		WHERE temp_flag = 1
		AND	arco.batch_proc_flag = 1

		
		SELECT	@home_curr_precision = home.curr_precision,
			@oper_curr_precision = oper.curr_precision
		FROM	glco, glcurr_vw home, glcurr_vw oper
		WHERE	glco.home_currency = home.currency_code
		AND	glco.oper_currency = oper.currency_code

		
		CREATE TABLE #code_totals
		(	
			code1		varchar(8),
			code2		varchar(8),
			code_type	smallint,
			home_total	float,
			oper_total	float
		)
	
		
		INSERT	#code_totals
		(
			code1,			code2,			code_type,
			home_total,		
			oper_total
		)
		SELECT customer_code, 	'',			0,
			SUM(ROUND(-1.0 * amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @home_curr_precision)),
			SUM(ROUND(-1.0 * amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @oper_curr_precision))
		FROM	#arvalchg
		WHERE	hold_flag = 0
		AND	temp_flag = 1	 
		GROUP BY customer_code

		
		INSERT	#code_totals
		(
			code1,			code2,			code_type,
			home_total,		
			oper_total
		)
		SELECT chg.price_code, 	'',			1,
			SUM(ROUND(-1.0 * chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_curr_precision)),
			SUM(ROUND(-1.0 * chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_curr_precision))
		FROM	#arvalchg chg, arco
		WHERE ( LTRIM(chg.price_code) IS NOT NULL AND LTRIM(chg.price_code) != " " )
		AND	chg.hold_flag = 0
		AND	chg.temp_flag = 1
		AND	arco.aractprc_flag = 1
		GROUP BY chg.price_code

		
		INSERT	#code_totals
		(
			code1,			code2,			code_type,
			home_total,		
			oper_total
		)
		SELECT chg.customer_code, 	chg.ship_to_code,	2,
			SUM(ROUND(-1.0 * chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_curr_precision)),
			SUM(ROUND(-1.0 * chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_curr_precision))
		FROM	#arvalchg chg, arco
		WHERE ( LTRIM(chg.ship_to_code) IS NOT NULL AND LTRIM(chg.ship_to_code) != " " )
		AND	chg.hold_flag = 0
		AND	chg.temp_flag = 1
		AND	arco.aractshp_flag = 1
		GROUP BY chg.customer_code, chg.ship_to_code

		
		INSERT	#code_totals
		(
			code1,			code2,			code_type,
			home_total,		
			oper_total
		)
		SELECT chg.salesperson_code, 	'',		3,
			SUM(ROUND(-1.0 * chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_curr_precision)),
			SUM(ROUND(-1.0 * chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_curr_precision))
		FROM	#arvalchg chg, arco
		WHERE ( LTRIM(chg.salesperson_code) IS NOT NULL AND LTRIM(chg.salesperson_code) != " " )
		AND	chg.hold_flag = 0
		AND	chg.temp_flag = 1
		AND	arco.aractslp_flag = 1
		GROUP BY chg.salesperson_code
		
		
		INSERT	#code_totals
		(
			code1,			code2,			code_type,
			home_total,		
			oper_total
		)
		SELECT chg.territory_code, 	'',			4,
			SUM(ROUND(-1.0 * chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_curr_precision)),
			SUM(ROUND(-1.0 * chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_curr_precision))
		FROM	#arvalchg chg, arco
		WHERE ( LTRIM(chg.territory_code) IS NOT NULL AND LTRIM(chg.territory_code) != " " )
		AND	chg.hold_flag = 0
		AND	chg.temp_flag = 1
		AND	arco.aractter_flag = 1
		GROUP BY chg.territory_code

		
 		BEGIN TRANSACTION 

		
		UPDATE	aractcus
		SET	amt_inv_unposted = aractcus.amt_inv_unposted + #code_totals.home_total,
			amt_inv_unp_oper = aractcus.amt_inv_unp_oper + #code_totals.oper_total
		FROM	#code_totals
		WHERE	aractcus.customer_code = #code_totals.code1
		AND	#code_totals.code_type = 0

		
		UPDATE	aractprc
		SET	amt_inv_unposted = amt_inv_unposted + #code_totals.home_total,
			amt_inv_unp_oper = amt_inv_unp_oper + #code_totals.oper_total
		FROM	#code_totals
		WHERE	aractprc.price_code = #code_totals.code1
		AND	#code_totals.code_type = 1

		
		UPDATE	aractshp
		SET	amt_inv_unposted = amt_inv_unposted + #code_totals.home_total,
			amt_inv_unp_oper = amt_inv_unp_oper + #code_totals.oper_total
		FROM	#code_totals
		WHERE	aractshp.customer_code = #code_totals.code1
		AND	aractshp.ship_to_code = #code_totals.code2
		AND	#code_totals.code_type = 2

		
		UPDATE	aractslp
		SET	amt_inv_unposted = amt_inv_unposted + #code_totals.home_total,
			amt_inv_unp_oper = amt_inv_unp_oper + #code_totals.oper_total
		FROM	#code_totals
		WHERE	aractslp.salesperson_code = #code_totals.code1
		AND	#code_totals.code_type = 3

		
		UPDATE	arinpchg
 		SET	hold_flag = 1
		FROM	#arvalchg val, arinpchg inp
		WHERE	val.trx_ctrl_num = inp.trx_ctrl_num
		AND	val.trx_type = inp.trx_type
		AND	val.temp_flag = 1 

		
	 	UPDATE batchctl
		SET hold_flag = 1,
		 number_held =(SELECT SUM(hold_flag) 
		 FROM	#arvalchg
					WHERE #arvalchg.batch_code = batchctl.batch_ctrl_num)
		FROM batchctl, #temp_batchcodes b
		WHERE batchctl.batch_ctrl_num = b.batch_code

		COMMIT TRANSACTION

		DROP TABLE #code_totals
	END
	
	DROP TABLE #temp_batchcodes

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arineh.sp" + ", line " + STR( 304, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINEditHold_SP] TO [public]
GO
