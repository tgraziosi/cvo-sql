SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAUpdateSummary_SP]	@batch_ctrl_num	varchar( 16 ),
					@perf_level		smallint = 0,
					@debug_level		int = 0

AS


DECLARE	@mast_flag		smallint,
		@price_flag		smallint,
		@ship_to_flag		smallint,
		@territory_flag	smallint,
		@salesperson_flag	smallint,
		@result		int,
		@home_precision	smallint,
		@oper_precision	smallint
BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaus.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

	
	SELECT	@home_precision = curr_precision
	FROM	glco, glcurr_vw
	WHERE	glco.home_currency = glcurr_vw.currency_code

	SELECT	@oper_precision = curr_precision
	FROM	glco, glcurr_vw
	WHERE	glco.oper_currency = glcurr_vw.currency_code

	

	SELECT	@salesperson_flag = arsumslp_flag,
		@price_flag = arsumprc_flag,
		@territory_flag = arsumter_flag,
		@ship_to_flag = arsumshp_flag
	FROM	arco

	IF ( @@ROWCOUNT = 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaus.sp" + ", line " + STR( 85, 5 ) + " -- EXIT: "
		RETURN 32124
	END

	
	INSERT	#arsumcus_work
	(
		customer_code,
		date_from,
		date_thru,
		num_adj,
		amt_adj,
		amt_adj_oper
	)
	SELECT	chg.customer_code,
		glprd.period_start_date,
		glprd.period_end_date,
		COUNT( chg.amt_net ),
		SUM( ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision ) ),
		SUM( ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision ) )
	FROM	#arinpchg_work chg, glprd
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	glprd.period_start_date <= chg.date_applied
	AND	glprd.period_end_date >= chg.date_applied
	GROUP BY chg.customer_code, glprd.period_start_date, glprd.period_end_date

	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaus.sp" + ", line " + STR( 115, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF ( @price_flag > 0 )
	BEGIN
		INSERT	#arsumprc_work
		(
			price_code,
			date_from,
			date_thru,
			num_adj,
			amt_adj,
			amt_adj_oper
		)
		SELECT	chg.price_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT( chg.amt_net ),
			SUM( ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision ) ),
			SUM( ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision ) )
		FROM	#arinpchg_work chg, glprd
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.price_code) IS NOT NULL AND LTRIM(chg.price_code) != " " )
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		GROUP BY chg.price_code, glprd.period_start_date, glprd.period_end_date

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaus.sp" + ", line " + STR( 148, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	IF ( @ship_to_flag > 0 )
	BEGIN
		INSERT	#arsumshp_work
		(
			customer_code,
			ship_to_code,
			date_from,
			date_thru,
			num_adj,
			amt_adj,
			amt_adj_oper
		)
		SELECT	chg.customer_code,
			chg.ship_to_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT( chg.amt_net ),
			SUM(ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision ) ),
			SUM(ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision ) )
		FROM	#arinpchg_work chg, glprd
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.ship_to_code) IS NOT NULL AND LTRIM(chg.ship_to_code) != " " )
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		GROUP BY chg.customer_code, chg.ship_to_code, glprd.period_start_date,glprd.period_end_date

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaus.sp" + ", line " + STR( 184, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	IF ( @salesperson_flag > 0 )
	BEGIN
		INSERT #arsumslp_work
		(
			salesperson_code,
			date_from,
			date_thru,
			num_adj,
			amt_adj,
			amt_adj_oper
		)
		SELECT	chg.salesperson_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT(chg.amt_net),
			SUM( ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision ) ),
			SUM( ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision ) )
		FROM	#arinpchg_work chg, glprd
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.salesperson_code) IS NOT NULL AND LTRIM(chg.salesperson_code) != " " )
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		GROUP BY chg.salesperson_code, glprd.period_start_date, glprd.period_end_date

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaus.sp" + ", line " + STR( 218, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	IF ( @territory_flag > 0 )
	BEGIN
		INSERT	#arsumter_work
		(
			territory_code,
			date_from,
			date_thru,
			num_adj,
			amt_adj,
			amt_adj_oper
		)
		SELECT	chg.territory_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT( chg.amt_net ),
			SUM(ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision ) ),
			SUM(ROUND( chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision ) )
		FROM	#arinpchg_work chg, glprd
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.territory_code) IS NOT NULL AND LTRIM(chg.territory_code) != " " )
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		GROUP BY chg.territory_code, glprd.period_start_date,glprd.period_end_date

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaus.sp" + ", line " + STR( 252, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaus.sp" + ", line " + STR( 257, 5 ) + " -- EXIT: "
	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[ARIAUpdateSummary_SP] TO [public]
GO
