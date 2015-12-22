SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCRUpdateSalesActivity_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrusa.sp", 68, "Entering ARCRUpdateSalespersonActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "

	
	INSERT	#aractslp_work
	(
		salesperson_code
	)
	SELECT	DISTINCT artrx.salesperson_code
	FROM	#arinppyt_work pyt, #artrxpdt_work pdt, #artrx_work artrx
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pdt.sub_apply_num = artrx.doc_ctrl_num
	AND	pdt.sub_apply_type = artrx.trx_type
	AND	pdt.db_action = 2
	AND	( LTRIM(artrx.salesperson_code) IS NOT NULL AND LTRIM(artrx.salesperson_code) != " " )
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 92, 5 ) + " -- EXIT: "
		RETURN 34563
	END

		
	
	UPDATE	#aractslp_work
	SET	amt_balance = ISNULL(amt_balance, 0.0) - 
		(
			ISNULL((SELECT SUM(ROUND((	pdt.inv_amt_applied 
						 + pdt.inv_amt_disc_taken 
						 + pdt.inv_amt_wr_off)
						 * ( SIGN(1 + SIGN(artrx.rate_home))*(artrx.rate_home) + (SIGN(ABS(SIGN(ROUND(artrx.rate_home,6))))/(artrx.rate_home + SIGN(1 - ABS(SIGN(ROUND(artrx.rate_home,6)))))) * SIGN(SIGN(artrx.rate_home) - 1) ), @home_precision)
						 )
			FROM	#arinppyt_work pyt, #artrxpdt_work pdt, #artrx_work artrx
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	pdt.sub_apply_num = artrx.doc_ctrl_num
			AND	pdt.sub_apply_type = artrx.trx_type
			AND	pdt.db_action = 2
			AND	#aractslp_work.salesperson_code = artrx.salesperson_code
			AND	pyt.non_ar_flag = 0),0.0)
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#aractslp_work
	SET	amt_balance_oper = ISNULL(amt_balance_oper, 0.0) - 
		(
			ISNULL((SELECT SUM(ROUND((	pdt.inv_amt_applied 
						 + pdt.inv_amt_disc_taken 
						 + pdt.inv_amt_wr_off)
						 * ( SIGN(1 + SIGN(artrx.rate_oper))*(artrx.rate_oper) + (SIGN(ABS(SIGN(ROUND(artrx.rate_oper,6))))/(artrx.rate_oper + SIGN(1 - ABS(SIGN(ROUND(artrx.rate_oper,6)))))) * SIGN(SIGN(artrx.rate_oper) - 1) ), @oper_precision)
						 )
			FROM	#arinppyt_work pyt, #artrxpdt_work pdt, #artrx_work artrx
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	pdt.sub_apply_num = artrx.doc_ctrl_num
			AND	pdt.sub_apply_type = artrx.trx_type
			AND	pdt.db_action = 2
			AND	#aractslp_work.salesperson_code = artrx.salesperson_code
			AND	pyt.non_ar_flag = 0),0.0)
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 147, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	
	SELECT artrx.salesperson_code, trx.trx_type, MAX(trx.trx_ctrl_num) trx_ctrl_num
	INTO	#max_trx
	FROM	#arinppyt_work inp, #artrxpdt_work	trx, #artrx_work artrx
	WHERE	inp.batch_code = @batch_ctrl_num
	AND	inp.trx_ctrl_num = trx.trx_ctrl_num
	AND	inp.trx_type = 2111
	AND	trx.sub_apply_num = artrx.doc_ctrl_num
	AND	trx.sub_apply_type = artrx.trx_type
	GROUP BY artrx.salesperson_code, trx.trx_type	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 172, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
				
	
	UPDATE	#aractslp_work
	SET	date_last_pyt = arinppyt.date_doc,
		amt_last_pyt = arinppyt.amt_payment,
		last_pyt_doc = arinppyt.doc_ctrl_num,
		last_pyt_cur = arinppyt.nat_cur_code
	FROM	#arinppyt_work arinppyt, #max_trx maxtrx
	WHERE	arinppyt.trx_ctrl_num = maxtrx.trx_ctrl_num
	AND	arinppyt.trx_type = maxtrx.trx_type
	AND	arinppyt.payment_type = 1
	AND	#aractslp_work.salesperson_code = maxtrx.salesperson_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 192, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#aractslp_work
	SET	date_last_pyt = trx.date_doc,
		amt_last_pyt = trx.amt_net,
		last_pyt_doc = trx.doc_ctrl_num,
		last_pyt_cur = trx.nat_cur_code
	FROM	#arinppyt_work arinppyt, #max_trx maxtrx, #artrx_work trx
	WHERE	arinppyt.payment_type = 2		
	AND	arinppyt.trx_ctrl_num = maxtrx.trx_ctrl_num
	AND	arinppyt.trx_type = maxtrx.trx_type
	AND	arinppyt.doc_ctrl_num = trx.doc_ctrl_num
	AND	arinppyt.customer_code = trx.customer_code
	AND	arinppyt.trx_type = trx.trx_type 
	AND	trx.payment_type = 1
	AND	#aractslp_work.salesperson_code = maxtrx.salesperson_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 215, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	

	DROP TABLE #max_trx

	
	
	
	CREATE TABLE #inv_paid_off
	(
		doc_ctrl_num	varchar(16),
		trx_type	int
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 241, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT	#inv_paid_off
	(	
		doc_ctrl_num,
		trx_type
	)
	SELECT	DISTINCT
		artrx.doc_ctrl_num,
		artrx.trx_type
	FROM	#arinppyt_work arinppyt, #artrxpdt_work artrxpdt, #artrx_work artrx
	WHERE	arinppyt.trx_ctrl_num = artrxpdt.trx_ctrl_num
	AND	arinppyt.trx_type = artrxpdt.trx_type
	AND	arinppyt.batch_code = @batch_ctrl_num
	AND	artrxpdt.sub_apply_num = artrx.doc_ctrl_num
	AND	artrxpdt.sub_apply_type = artrx.trx_type
	AND	artrx.trx_type <= 2031 
	AND	artrx.paid_flag = 1
	AND	( LTRIM(salesperson_code) IS NOT NULL AND LTRIM(salesperson_code) != " " )
	AND	artrxpdt.db_action = 2
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 265, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	CREATE TABLE #invoices_paid
	(
		salesperson_code		varchar(8),
		num_inv_paid		int,
		num_overdue_pyt	int,
		sum_days_to_pay_off	int,
		sum_days_overdue	int		
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 280, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT	#invoices_paid
	(	
		salesperson_code,
		num_inv_paid,
		num_overdue_pyt,
		sum_days_to_pay_off,
		sum_days_overdue		
	)
	SELECT
		artrx.salesperson_code,
		SUM(artrx.paid_flag),
		SUM(SIGN( 1 + SIGN(artrx.date_paid - 0.5 - artrx.date_due)) * artrx.paid_flag),
		SUM(SIGN( 1 + SIGN(artrx.date_paid - artrx.date_doc)) * (artrx.date_paid - artrx.date_doc)),
		SUM(SIGN( 1 + SIGN(artrx.date_paid - artrx.date_due)) * (artrx.date_paid - artrx.date_due))
	FROM	#artrx_work artrx, #inv_paid_off inv
	WHERE	artrx.doc_ctrl_num = inv.doc_ctrl_num
	AND	artrx.trx_type = inv.trx_type	
	GROUP BY artrx.salesperson_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 304, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #inv_paid_off
			
	UPDATE	#aractslp_work
	SET	num_inv_paid = a.num_inv_paid,
		num_overdue_pyt = a.num_overdue_pyt,
		sum_days_to_pay_off = a.sum_days_to_pay_off,
		sum_days_overdue = a.sum_days_overdue
	FROM	#invoices_paid a
	WHERE	#aractslp_work.salesperson_code = a.salesperson_code		
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 322, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #invoices_paid

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrusa.sp" + ", line " + STR( 328, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCRUpdateSalesActivity_SP] TO [public]
GO
