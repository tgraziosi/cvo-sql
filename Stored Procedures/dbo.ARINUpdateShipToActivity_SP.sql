SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINUpdateShipToActivity_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint,
						@perf_level		smallint,
						@home_precision	smallint,
						@oper_precision	smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinusta.sp", 65, "Entering ARINUpdateShipToActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 68, 5 ) + " -- ENTRY: "

	
	INSERT	#aractshp_work
	(
		customer_code,
		ship_to_code
	)
	SELECT	DISTINCT 
		arinpchg.customer_code,
		arinpchg.ship_to_code
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	( LTRIM(arinpchg.ship_to_code) IS NOT NULL AND LTRIM(arinpchg.ship_to_code) != " " )
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 87, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractshp_work
	SET	amt_balance = 
		(
			SELECT	SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision))
			FROM	#arinpchg_work chg
			WHERE	chg.batch_code = @batch_ctrl_num
			AND	#aractshp_work.customer_code = chg.customer_code
			AND	#aractshp_work.ship_to_code = chg.ship_to_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 105, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#aractshp_work
	SET	amt_balance_oper = 
		(
			SELECT	SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision))
			FROM	#arinpchg_work chg
			WHERE	chg.batch_code = @batch_ctrl_num
			AND	#aractshp_work.customer_code = chg.customer_code
			AND	#aractshp_work.ship_to_code = chg.ship_to_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractshp_work
	SET	amt_inv_unposted = -1 * amt_balance,
		amt_inv_unp_oper = -1 * amt_balance_oper
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 133, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractshp_work
	SET	num_inv = 
		(
			SELECT	COUNT(arinpchg.amt_net)
			FROM	#arinpchg_work arinpchg
			WHERE	arinpchg.batch_code = @batch_ctrl_num
			AND	#aractshp_work.customer_code = arinpchg.customer_code
			AND	#aractshp_work.ship_to_code = arinpchg.ship_to_code
			AND	trx_type = apply_trx_type 
			AND	doc_ctrl_num = apply_to_num
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 154, 5 ) + " -- EXIT: "
		RETURN 34563
	END

		
	UPDATE	#aractshp_work
	SET	last_inv_doc = arinpchg.doc_ctrl_num,
		amt_last_inv = arinpchg.amt_net,
		date_last_inv = arinpchg.date_doc,
		last_inv_cur = arinpchg.nat_cur_code		
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.customer_code = #aractshp_work.customer_code
	AND	arinpchg.ship_to_code = #aractshp_work.ship_to_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 172, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	SELECT	chg.customer_code,
		chg.ship_to_code,
		chg.date_applied,
		SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)) high_amt_ar,
		MAX(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)) high_amt_inv,
		SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)) high_amt_ar_oper,
		MAX(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)) high_amt_inv_oper
	INTO	#high_amounts
	FROM	#arinpchg_work chg
	WHERE	chg.batch_code = @batch_ctrl_num
	GROUP BY chg.customer_code, chg.ship_to_code, chg.date_applied
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 192, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#aractshp_work
	SET	high_date_ar = #high_amounts.date_applied,
		high_date_inv = #high_amounts.date_applied,
		high_amt_ar = #high_amounts.high_amt_ar,
		high_amt_inv = #high_amounts.high_amt_inv,
		high_amt_ar_oper = #high_amounts.high_amt_ar_oper,
		high_amt_inv_oper = #high_amounts.high_amt_inv_oper
	FROM	#high_amounts
	WHERE	#high_amounts.customer_code = #aractshp_work.customer_code
	AND	#high_amounts.ship_to_code = #aractshp_work.ship_to_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 208, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE	#high_amounts
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 215, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusta.sp" + ", line " + STR( 219, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARINUpdateShipToActivity_SP] TO [public]
GO
