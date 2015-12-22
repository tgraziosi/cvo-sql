SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLUpdateShipToSummary_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint,
						@perf_level		smallint,
						@home_precision	int,
						@oper_precision	int
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflusts.sp", 69, "Entering ARFLUpdateShipToSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflusts.sp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "
	
	
	INSERT	#arsumshp_work
	(
		customer_code,
		ship_to_code,
		date_from,
		date_thru,
		amt_fin_chg,
		amt_fin_chg_oper,
		amt_late_chg,
		amt_late_chg_oper
	)
	SELECT 
		trx.customer_code,
		trx.ship_to_code,
		glprd.period_start_date,
		glprd.period_end_date,
		SUM(ROUND(trx.amt_net* ( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), @home_precision)
			*SIGN(2071-trx_type)),
		SUM(ROUND(trx.amt_net* ( SIGN(1 + SIGN(trx.rate_oper))*(trx.rate_oper) + (SIGN(ABS(SIGN(ROUND(trx.rate_oper,6))))/(trx.rate_oper + SIGN(1 - ABS(SIGN(ROUND(trx.rate_oper,6)))))) * SIGN(SIGN(trx.rate_oper) - 1) ), @oper_precision)
			*SIGN(2071-trx_type)),
		SUM(ROUND(trx.amt_net* ( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), @home_precision)
			*(1-SIGN(2071-trx_type))),
		SUM(ROUND(trx.amt_net* ( SIGN(1 + SIGN(trx.rate_oper))*(trx.rate_oper) + (SIGN(ABS(SIGN(ROUND(trx.rate_oper,6))))/(trx.rate_oper + SIGN(1 - ABS(SIGN(ROUND(trx.rate_oper,6)))))) * SIGN(SIGN(trx.rate_oper) - 1) ), @oper_precision)
			*(1-SIGN(2071-trx_type)))
	FROM	glprd, #artrx_work trx
	WHERE	trx.trx_type >= 2061
	AND	trx.trx_type <= 2071
	AND	glprd.period_start_date <= trx.date_applied
	AND	glprd.period_end_date >= trx.date_applied
	AND	( LTRIM(trx.ship_to_code) IS NOT NULL AND LTRIM(trx.ship_to_code) != " " )
	GROUP BY trx.customer_code, trx.ship_to_code,
		glprd.period_start_date, glprd.period_end_date
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflusts.sp" + ", line " + STR( 110, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#arsumshp_work
	SET	num_fin_chg = (	SELECT COUNT(trx.customer_code)
				 	FROM	#artrx_work trx
				 	WHERE	trx.trx_type = 2061
					AND	trx.customer_code = #arsumshp_work.customer_code
					AND	trx.ship_to_code = #arsumshp_work.ship_to_code
				 ),
		num_late_chg= (	SELECT COUNT(trx.customer_code)
					FROM	#artrx_work trx
					WHERE	trx.trx_type = 2071
					AND	trx.customer_code = #arsumshp_work.customer_code
					AND	trx.ship_to_code = #arsumshp_work.ship_to_code
				)
				
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflusts.sp" + ", line " + STR( 133, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level >= 2 )
	BEGIN
		SELECT "dumping #arsumshp_work...."
		SELECT "customer_code = " + customer_code +
			"ship_to_code = " + ship_to_code +
			"date_from = " + STR(date_from, 8) +
			"amt_fin_chg = " + STR(amt_fin_chg, 10, 2) +
			"amt_late_chg = " + STR(amt_late_chg, 10, 2) +
			"num_late_chg = " + STR(num_late_chg, 6) +
			"num_fin_chg = " + STR(num_fin_chg, 6)
		FROM	#arsumshp_work
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflusts.sp" + ", line " + STR( 150, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARFLUpdateShipToSummary_SP] TO [public]
GO
