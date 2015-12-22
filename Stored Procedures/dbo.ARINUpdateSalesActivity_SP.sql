SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINUpdateSalesActivity_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinusa.sp", 65, "Entering ARINUpdateSalesActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 68, 5 ) + " -- ENTRY: "

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 74, 5 ) + " -- MSG: " + "  Insert all the records that may be updated into the #aractslp_work table."
	INSERT	#aractslp_work
	(
		salesperson_code
	)
	SELECT	DISTINCT arinpchg.salesperson_code
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	( LTRIM(arinpchg.salesperson_code) IS NOT NULL AND LTRIM(arinpchg.salesperson_code) != " " ) 
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 85, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 92, 5 ) + " -- MSG: " + "  Update the amt_balance on the customer activity table"
	UPDATE	#aractslp_work
	SET	amt_balance = 
		(
			SELECT	SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision))
			FROM	#arinpchg_work chg
			WHERE	chg.batch_code = @batch_ctrl_num
			AND	#aractslp_work.salesperson_code = chg.salesperson_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 103, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#aractslp_work
	SET	amt_balance_oper = 
		(
			SELECT	SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision))
			FROM	#arinpchg_work chg
			WHERE	chg.batch_code = @batch_ctrl_num
			AND	#aractslp_work.salesperson_code = chg.salesperson_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 124, 5 ) + " -- MSG: " + "  Reduce the amount of unposted invoices by the same amount that we reduced above"
	UPDATE	#aractslp_work
	SET	amt_inv_unposted = -1 * amt_balance,
		amt_inv_unp_oper = -1 * amt_balance_oper
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 130, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 138, 5 ) + " -- MSG: " + "  Get the number of invoices posted. Note that this only applys to master invoices."
	UPDATE	#aractslp_work
	SET	num_inv = 
		(
			SELECT	COUNT(arinpchg.amt_net)
			FROM	#arinpchg_work arinpchg
			WHERE	arinpchg.batch_code = @batch_ctrl_num
			AND	#aractslp_work.salesperson_code = arinpchg.salesperson_code
			AND	trx_type = apply_trx_type 
			AND	doc_ctrl_num = apply_to_num
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 151, 5 ) + " -- EXIT: "
		RETURN 34563
	END

		
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 158, 5 ) + " -- MSG: " + "  Update the last invoice information"
	UPDATE	#aractslp_work
	SET	last_inv_doc = arinpchg.doc_ctrl_num,
		amt_last_inv = arinpchg.amt_net,
		date_last_inv = arinpchg.date_doc,
		last_inv_cur = arinpchg.nat_cur_code		
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.salesperson_code = #aractslp_work.salesperson_code
	AND	arinpchg.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 169, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 176, 5 ) + " -- MSG: " + "  Update the high ar amount for this batch"
	SELECT	chg.salesperson_code,
		chg.date_applied,
		SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)) high_amt_ar,
		MAX(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), @home_precision)) high_amt_inv,
		SUM(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)) high_amt_ar_oper,
		MAX(ROUND(chg.amt_net * ( SIGN(1 + SIGN(chg.rate_oper))*(chg.rate_oper) + (SIGN(ABS(SIGN(ROUND(chg.rate_oper,6))))/(chg.rate_oper + SIGN(1 - ABS(SIGN(ROUND(chg.rate_oper,6)))))) * SIGN(SIGN(chg.rate_oper) - 1) ), @oper_precision)) high_amt_inv_oper
	INTO	#high_amounts
	FROM	#arinpchg_work chg
	WHERE	chg.batch_code = @batch_ctrl_num
	GROUP BY chg.salesperson_code, chg.date_applied
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 189, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 196, 5 ) + " -- MSG: " + "	update #aractslp_work from #high_amount table"
	UPDATE	#aractslp_work
	SET	high_date_ar = #high_amounts.date_applied,
		high_date_inv = #high_amounts.date_applied,
		high_amt_ar = #high_amounts.high_amt_ar,
		high_amt_inv = #high_amounts.high_amt_inv,
		high_amt_ar_oper = #high_amounts.high_amt_ar_oper,
		high_amt_inv_oper = #high_amounts.high_amt_inv_oper
	FROM	#high_amounts
	WHERE	#high_amounts.salesperson_code = #aractslp_work.salesperson_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 208, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 215, 5 ) + " -- MSG: " + "	drop table #high_amounts"
	DROP TABLE	#high_amounts
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 219, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinusa.sp" + ", line " + STR( 223, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARINUpdateSalesActivity_SP] TO [public]
GO
