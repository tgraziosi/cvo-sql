SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARFLUpdatePriceActivity_SP]	@batch_ctrl_num	varchar( 16 ),
							@debug_level		smallint,
							@perf_level		smallint,
							@home_precision	int,
							@oper_precision	int
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int,
	@process_ctrl_num	varchar( 16 ),
	@user_id		smallint,
	@date_entered		int,
	@period_end		int,
	@batch_type		smallint

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflupa.sp", 79, "Entering ARFLUpdatePriceActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 82, 5 ) + " -- ENTRY: "
	
	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@user_id OUTPUT,
					@date_entered OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 95, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	
	INSERT	#aractprc_work
	(
		price_code
	)
	SELECT	DISTINCT price_code
	FROM	#artrx_work
	WHERE	trx_type >= 2061
	AND	trx_type <= 2071
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 113, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractprc_work
	SET amt_balance = ISNULL(amt_balance, 0.0) + 
			 	(	
			 		SELECT ISNULL(SUM(ROUND(amt_net*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @home_precision)),0.0)
					FROM	#artrx_work
					WHERE	trx_type >= 2061
					AND	trx_type <= 2071
					AND	#aractprc_work.price_code = #artrx_work.price_code
			 	)
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 132, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#aractprc_work
	SET amt_balance_oper = ISNULL(amt_balance_oper, 0.0) + 
			 	(	
			 		SELECT ISNULL(SUM(ROUND(amt_net*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @oper_precision)),0.0)
					FROM	#artrx_work
					WHERE	trx_type >= 2061
					AND	trx_type <= 2071
					AND	#aractprc_work.price_code = #artrx_work.price_code
			 	)
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 151, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	CREATE TABLE	#max_trx
	(
	 	character_8		varchar(8),
		trx_type		smallint,
	 	trx_ctrl_num		varchar(16)
 	)
	IF( @@error != 0 )
	BEGIN
	 	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 166, 5 ) + " -- EXIT: "
	 	RETURN 34563
	END
	
	INSERT	#max_trx (character_8, trx_type, trx_ctrl_num)
	SELECT	price_code,
		trx_type,
		MAX(trx_ctrl_num)
	FROM	#artrx_work
	WHERE	trx_type >= 2061
	AND	trx_type <= 2071
	GROUP BY price_code, trx_type

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 181, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractprc_work
	SET	date_last_fin_chg = @date_entered,
		amt_last_fin_chg = trx.amt_net,
		last_fin_chg_doc = trx.doc_ctrl_num,
		last_fin_chg_cur = trx.nat_cur_code
	FROM	#artrx_work trx, #max_trx m
	WHERE	trx.price_code = m.character_8
	AND	trx.trx_ctrl_num = m.trx_ctrl_num
	AND	m.trx_type = 2061
	
	
	UPDATE	#aractprc_work
	SET	date_last_late_chg = @date_entered,
		amt_last_late_chg = trx.amt_net,
		last_late_chg_doc = trx.doc_ctrl_num,
		last_late_chg_cur = trx.nat_cur_code
	FROM	#artrx_work trx, #max_trx m
	WHERE	trx.price_code = m.character_8
	AND	trx.trx_ctrl_num = m.trx_ctrl_num
	AND	m.trx_type = 2071

 	
	SELECT	price_code,
		SUM(ROUND(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @home_precision)) high_amt_ar,
		SUM(ROUND(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @oper_precision)) high_amt_ar_oper
	INTO	#high_amounts
	FROM	#artrx_work
	WHERE	trx_type >= 2061
	AND	trx_type <= 2071
	GROUP BY price_code
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 225, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractprc_work
	SET	high_date_ar = @date_entered,
		high_amt_ar = #high_amounts.high_amt_ar,
		high_amt_ar_oper = #high_amounts.high_amt_ar_oper
	FROM	#high_amounts
	WHERE	#high_amounts.price_code = #aractprc_work.price_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 241, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	IF ( @debug_level >= 2 )
	BEGIN
		SELECT "dumping #aractprc_work..."
		SELECT "price_code = " + price_code +
			"amt_balance = " + STR(amt_balance, 10, 2) +
			"amt_balance_oper = " + STR(amt_balance_oper, 10, 2) +
			"amt_last_late_chg = " + STR(amt_last_late_chg, 10, 2 ) + 
			"amt_last_fin_chg = " + STR(amt_last_fin_chg, 10, 2 )
		FROM	#aractprc_work
	END
			 
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflupa.sp" + ", line " + STR( 256, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARFLUpdatePriceActivity_SP] TO [public]
GO
