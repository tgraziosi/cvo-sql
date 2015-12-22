SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARINUpdateSummary_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint,
					@perf_level		smallint,
					@home_precision	smallint,
					@oper_precision	smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int,
        @arsumcus_flag int,
        @arsumslp_flag int, 
        @arsumprc_flag int,
        @arsumter_flag int,
        @arsumshp_flag int
        
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinus.sp", 71, "Entering ARINUpdateSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinus.sp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "

SELECT @arsumcus_flag = 0,
        @arsumslp_flag = 0, 
        @arsumprc_flag = 0,
        @arsumter_flag = 0,
        @arsumshp_flag = 0

 SELECT @arsumcus_flag = arsumcus_flag,
        @arsumslp_flag = arsumslp_flag, 
        @arsumprc_flag = arsumprc_flag,
        @arsumter_flag = arsumter_flag,
        @arsumshp_flag = arsumshp_flag
	FROM	arco (nolock)

	IF (  @arsumcus_flag = 1 )
	BEGIN
		INSERT	#arsumcus_work
		(
			customer_code,
			date_from,
			date_thru,
			num_inv,
			amt_inv,
			amt_profit,
			amt_disc_given,
			amt_freight,
			amt_tax,
			amt_inv_oper,
			amt_disc_g_oper,	
			amt_freight_oper,
			amt_tax_oper	
		)
		SELECT	chg.customer_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT(chg.amt_net),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(chg.amt_profit),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ),@oper_precision)),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision))
		FROM	#arinpchg_work chg, glprd (nolock)
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		GROUP BY chg.customer_code, glprd.period_start_date, glprd.period_end_date
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinus.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END
							
	
	IF ( @arsumslp_flag = 1	)
	BEGIN
		INSERT	#arsumslp_work
		(
			salesperson_code,
			date_from,
			date_thru,
			num_inv,
			amt_inv,
			amt_profit,
			amt_disc_given,
			amt_freight,
			amt_tax,
			amt_inv_oper,
			amt_disc_g_oper,	
			amt_freight_oper,
			amt_tax_oper	
		)
		SELECT	chg.salesperson_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT(chg.amt_net),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ),@home_precision)),
			SUM(chg.amt_profit),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ),@oper_precision)),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision))
		FROM	#arinpchg_work chg, glprd (nolock)
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		AND	( LTRIM(chg.salesperson_code) IS NOT NULL AND LTRIM(chg.salesperson_code) != " " ) 
		GROUP BY chg.salesperson_code, glprd.period_start_date, glprd.period_end_date
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinus.sp" + ", line " + STR( 166, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	
	END
	
	
	IF  ( @arsumprc_flag = 1 )
	BEGIN
		INSERT	#arsumprc_work
		(
			price_code,
			date_from,
			date_thru,
			num_inv,
			amt_inv,
			amt_profit,
			amt_disc_given,
			amt_freight,
			amt_tax,
			amt_inv_oper,
			amt_disc_g_oper,	
			amt_freight_oper,
			amt_tax_oper	
		)
		SELECT	chg.price_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT(chg.amt_net),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ),@home_precision)),
			SUM(chg.amt_profit),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ),@oper_precision)),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision))
		FROM	#arinpchg_work chg, glprd (nolock)
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		AND	( LTRIM(chg.price_code) IS NOT NULL AND LTRIM(chg.price_code) != " " ) 
		GROUP BY chg.price_code, glprd.period_start_date, glprd.period_end_date
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinus.sp" + ", line " + STR( 216, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	IF (@arsumter_flag = 1)
	BEGIN
		INSERT	#arsumter_work
		(
			territory_code,
			date_from,
			date_thru,
			num_inv,
			amt_inv,
			amt_profit,
			amt_disc_given,
			amt_freight,
			amt_tax,
			amt_inv_oper,
			amt_disc_g_oper,	
			amt_freight_oper,
			amt_tax_oper	
		)
		SELECT	chg.territory_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT(chg.amt_net),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ),@home_precision)),
			SUM(chg.amt_profit),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ),@oper_precision)),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision))
		FROM	#arinpchg_work chg, glprd (nolock)
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.territory_code) IS NOT NULL AND LTRIM(chg.territory_code) != " " ) 
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		GROUP BY chg.territory_code, glprd.period_start_date, glprd.period_end_date
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinus.sp" + ", line " + STR( 265, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END
	
	
	IF (@arsumshp_flag = 1)
	BEGIN
		INSERT	#arsumshp_work
		(
			customer_code,
			ship_to_code,
			date_from,
			date_thru,
			num_inv,
			amt_inv,
			amt_profit,
			amt_disc_given,
			amt_freight,
			amt_tax,
			amt_inv_oper,
			amt_disc_g_oper,	
			amt_freight_oper,
			amt_tax_oper	
		)
		SELECT	chg.customer_code,
			chg.ship_to_code,
			glprd.period_start_date,
			glprd.period_end_date,
			COUNT(chg.amt_net),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ),@home_precision)),
			SUM(chg.amt_profit),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)),
			SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ),@oper_precision)),
			SUM(ROUND(chg.amt_discount * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_freight * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)),
			SUM(ROUND(chg.amt_tax * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision))
		FROM	#arinpchg_work chg, glprd (nolock)
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.ship_to_code) IS NOT NULL AND LTRIM(chg.ship_to_code) != " " ) 
		AND	glprd.period_start_date <= chg.date_applied
		AND	glprd.period_end_date >= chg.date_applied
		GROUP BY chg.customer_code, chg.ship_to_code, glprd.period_start_date, glprd.period_end_date
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinus.sp" + ", line " + STR( 316, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinus.sp", 321, "Leaving ARINUpdateSummary_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinus.sp" + ", line " + STR( 322, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARINUpdateSummary_SP] TO [public]
GO
