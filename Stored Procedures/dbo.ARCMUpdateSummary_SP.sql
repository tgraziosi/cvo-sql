SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMUpdateSummary_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint,
					@perf_level		smallint
AS
DECLARE	@home_prec	smallint,
		@oper_prec	smallint







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmus.sp", 69, "Entering ARCMSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "

	SELECT	@home_prec = h.curr_precision,
		@oper_prec = o.curr_precision
	FROM	glco, glcurr_vw h, glcurr_vw o
	WHERE	glco.home_currency = h.currency_code
	AND	glco.oper_currency = o.currency_code

	
	CREATE TABLE	#ar_summary
	(
		trx_ctrl_num		varchar( 16 ),
		date_applied		int,
		period_end_date	int,
		period_start_date	int,
		amt_cm			float NULL
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 94, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT	#ar_summary
	(
		trx_ctrl_num,
		date_applied,
		period_start_date,
		period_end_date
	)
	SELECT	trx_ctrl_num,
		date_applied,
		0,
		0
	FROM	#arinpchg_work
	WHERE	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 113, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#ar_summary
	SET	period_end_date = glprd.period_end_date,
		period_start_date = glprd.period_start_date
	FROM	#ar_summary, glprd	
	WHERE	#ar_summary.date_applied >= glprd.period_start_date
	AND	#ar_summary.date_applied <= glprd.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 129, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#ar_summary
	SET	amt_cm = arinpchg.amt_net
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.recurring_flag = 1
	AND	arinpchg.trx_ctrl_num = #ar_summary.trx_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 145, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#ar_summary
	SET	amt_cm = arinpchg.amt_tax
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.recurring_flag = 2
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 155, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#ar_summary
	SET	amt_cm = arinpchg.amt_freight
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.recurring_flag = 3
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 165, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#ar_summary
	SET	amt_cm = arinpchg.amt_freight + arinpchg.amt_tax
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.recurring_flag = 4
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 175, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	INSERT	#arsumcus_work
	(
		customer_code,
		date_from,
		date_thru,
		amt_profit,
		num_cm,
		amt_tax,
		amt_disc_given,
		amt_freight,
		amt_cm,
		amt_tax_oper,
		amt_disc_g_oper,
		amt_freight_oper,
		amt_cm_oper
	)
	SELECT	arinpchg.customer_code,
		summary.period_start_date,
		summary.period_end_date,
		SUM(-1 * ROUND((arinpchg.amt_gross - arinpchg.amt_discount - arinpchg.amt_cost) * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		COUNT(*),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ),@home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec))
	FROM	#arinpchg_work arinpchg, arco, #ar_summary summary
	WHERE	arco.aractcus_flag = 1
	AND	arinpchg.trx_ctrl_num = summary.trx_ctrl_num
	GROUP BY arinpchg.customer_code, summary.period_start_date, summary.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 221, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	INSERT	#arsumprc_work
	(
		price_code,
		date_from,
		date_thru,
		amt_profit,
		num_cm,
		amt_tax,
		amt_disc_given,
		amt_freight,
		amt_cm,
		amt_tax_oper,
		amt_disc_g_oper,
		amt_freight_oper,
		amt_cm_oper
	)
	SELECT	arinpchg.price_code,
		summary.period_start_date,
		summary.period_end_date,
		SUM(-1 * ROUND((arinpchg.amt_gross - arinpchg.amt_discount - arinpchg.amt_cost) * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		COUNT(*),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec))
	FROM	#arinpchg_work arinpchg, arco, #ar_summary summary
	WHERE	arco.aractprc_flag = 1
	AND	arinpchg.trx_ctrl_num = summary.trx_ctrl_num
	AND	( LTRIM(arinpchg.price_code) IS NOT NULL AND LTRIM(arinpchg.price_code) != " " )
	GROUP BY price_code, summary.period_start_date, summary.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 265, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	INSERT	#arsumshp_work
	(
		ship_to_code,
		customer_code,
		date_from,
		date_thru,
		amt_profit,
		num_cm,
		amt_tax,
		amt_disc_given,
		amt_freight,
		amt_cm,
		amt_tax_oper,
		amt_disc_g_oper,
		amt_freight_oper,
		amt_cm_oper
	)
	SELECT	arinpchg.ship_to_code,
		arinpchg.customer_code,
		summary.period_start_date,
		summary.period_end_date,
		SUM(-1 * ROUND((arinpchg.amt_gross - arinpchg.amt_discount - arinpchg.amt_cost) * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		COUNT(*),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec))
	FROM	#arinpchg_work arinpchg, arco, #ar_summary summary
	WHERE	arco.aractshp_flag = 1
	AND	arinpchg.trx_ctrl_num = summary.trx_ctrl_num
	AND	( LTRIM(arinpchg.ship_to_code) IS NOT NULL AND LTRIM(arinpchg.ship_to_code) != " " )
	GROUP BY customer_code, ship_to_code, summary.period_start_date, summary.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 311, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	INSERT	#arsumslp_work
	(
		salesperson_code,
		date_from,
		date_thru,
		amt_profit,
		num_cm,
		amt_tax,
		amt_disc_given,
		amt_freight,
		amt_cm,
		amt_tax_oper,
		amt_disc_g_oper,
		amt_freight_oper,
		amt_cm_oper
	)
	SELECT	arinpchg.salesperson_code,
		summary.period_start_date,
		summary.period_end_date,
		SUM(-1 * ROUND((arinpchg.amt_gross - arinpchg.amt_discount - arinpchg.amt_cost) * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		COUNT(*),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec))
	FROM	#arinpchg_work arinpchg, arco, #ar_summary summary
	WHERE	arco.aractslp_flag = 1
	AND	arinpchg.trx_ctrl_num = summary.trx_ctrl_num
	AND	( LTRIM(arinpchg.customer_code) IS NOT NULL AND LTRIM(arinpchg.customer_code) != " " )
	GROUP BY salesperson_code, summary.period_start_date, summary.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 355, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	INSERT	#arsumter_work
	(
		territory_code,
		date_from,
		date_thru,
		amt_profit,
		num_cm,
		amt_tax,
		amt_disc_given,
		amt_freight,
		amt_cm,
		amt_tax_oper,
		amt_disc_g_oper,
		amt_freight_oper,
		amt_cm_oper
	)
	SELECT	arinpchg.territory_code,
		summary.period_start_date,
		summary.period_end_date,
		SUM(-1 * ROUND((arinpchg.amt_gross - arinpchg.amt_discount - arinpchg.amt_cost) * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		COUNT(*),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_home))*(arinpchg.rate_home) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_home,6))))/(arinpchg.rate_home + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_home,6)))))) * SIGN(SIGN(arinpchg.rate_home) - 1) ), @home_prec)),
		SUM(-1 * ROUND(arinpchg.amt_tax * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_discount * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(-1 * ROUND(arinpchg.amt_freight * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec)),
		SUM(ROUND(summary.amt_cm * ( SIGN(1 + SIGN(arinpchg.rate_oper))*(arinpchg.rate_oper) + (SIGN(ABS(SIGN(ROUND(arinpchg.rate_oper,6))))/(arinpchg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(arinpchg.rate_oper,6)))))) * SIGN(SIGN(arinpchg.rate_oper) - 1) ), @oper_prec))
	FROM	#arinpchg_work arinpchg, arco, #ar_summary summary
	WHERE	arco.aractter_flag = 1
	AND	arinpchg.trx_ctrl_num = summary.trx_ctrl_num
	AND	( LTRIM(arinpchg.territory_code) IS NOT NULL AND LTRIM(arinpchg.territory_code) != " " )
	GROUP BY territory_code, summary.period_start_date, summary.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 399, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #ar_summary

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmus.sp", 405, "Leaving ARCMUpdateSummary_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmus.sp" + ", line " + STR( 406, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMUpdateSummary_SP] TO [public]
GO
