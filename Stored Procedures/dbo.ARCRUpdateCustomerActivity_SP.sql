SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCRUpdateCustomerActivity_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcruca.sp", 77, "Entering ARCRUpdateCustomerActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 80, 5 ) + " -- ENTRY: "
	
	
	INSERT	#aractcus_work
	(
		customer_code
	)
	SELECT	DISTINCT arinppyt.customer_code
	FROM	#arinppyt_work arinppyt
	WHERE	arinppyt.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 95, 5 ) + " -- EXIT: "
		RETURN 34563
	END

			
	INSERT	#aractcus_work
	(
		customer_code
 )	
	SELECT	DISTINCT arinppdt.customer_code
	FROM	#arinppdt_work arinppdt, #arinppyt_work arinppyt 
	WHERE	arinppyt.batch_code = @batch_ctrl_num
	AND	arinppyt.trx_ctrl_num = arinppdt.trx_ctrl_num
	AND	arinppyt.trx_type = arinppdt.trx_type 
	AND	arinppdt.customer_code != arinppdt.payer_cust_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 118, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractcus_work
	SET	amt_on_acct = 
		(
			SELECT	ISNULL( SUM(ROUND(pyt.amt_on_acct*( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)), 0.0 )
			FROM	#arinppyt_work pyt
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	payment_type in ( 1, 3 )
			AND	#aractcus_work.customer_code = pyt.customer_code
			AND	pyt.non_ar_flag = 0
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 138, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#aractcus_work
	SET	amt_on_acct = ISNULL(amt_on_acct, 0.0) - 
		(
			SELECT	ISNULL(SUM(ROUND(pdt.amt_applied*( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)), 0.0 )
			FROM	#arinppyt_work pyt, #arinppdt_work pdt
			WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	payment_type in ( 2, 4 )
			AND	pyt.batch_code = @batch_ctrl_num
			AND	pyt.customer_code = #aractcus_work.customer_code
			AND	pyt.non_ar_flag = 0
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 160, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#aractcus_work
	SET	amt_balance = ISNULL(amt_balance, 0.0) - 
		(
		 	SELECT	ISNULL( SUM( ROUND((	pdt.inv_amt_applied 
		 				 + pdt.inv_amt_disc_taken 
		 				 + pdt.inv_amt_wr_off)*( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), @home_precision)
		 				), 
				 	 0.0)
			FROM	#arinppyt_work pyt, #artrxpdt_work pdt, #artrx_work trx
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	pyt.non_ar_flag = 0
			AND	pdt.db_action = 2
			AND	pdt.sub_apply_num = trx.doc_ctrl_num
			AND	pdt.sub_apply_type = trx.trx_type
			AND	#aractcus_work.customer_code = pdt.customer_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 188, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#aractcus_work
	SET	amt_on_acct_oper = 
		(
			SELECT	ISNULL( SUM(ROUND(pyt.amt_on_acct*( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision)), 0.0 )
			FROM	#arinppyt_work pyt
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	payment_type in ( 1, 3 )
			AND	#aractcus_work.customer_code = pyt.customer_code
			AND	pyt.non_ar_flag = 0
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 208, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractcus_work
	SET	amt_on_acct_oper = ISNULL(amt_on_acct_oper, 0.0) - 
		(
			SELECT	ISNULL(SUM(ROUND(pdt.amt_applied*( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision)), 0.0 )
			FROM	#arinppyt_work pyt, #arinppdt_work pdt
			WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	payment_type in ( 2, 4 )
			AND	pyt.batch_code = @batch_ctrl_num
			AND	pyt.customer_code = #aractcus_work.customer_code
			AND	pyt.non_ar_flag = 0
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 230, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractcus_work
	SET	amt_balance_oper = ISNULL(amt_balance_oper, 0.0) - 
		(
		 	SELECT	ISNULL( SUM( ROUND((	pdt.inv_amt_applied 
		 				 + pdt.inv_amt_disc_taken 
		 				 + pdt.inv_amt_wr_off)*( SIGN(1 + SIGN(trx.rate_oper))*(trx.rate_oper) + (SIGN(ABS(SIGN(ROUND(trx.rate_oper,6))))/(trx.rate_oper + SIGN(1 - ABS(SIGN(ROUND(trx.rate_oper,6)))))) * SIGN(SIGN(trx.rate_oper) - 1) ), @oper_precision)
						), 
				 	 0.0)
			FROM	#arinppyt_work pyt, #artrxpdt_work pdt, #artrx_work trx
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	pyt.non_ar_flag = 0
			AND	pdt.db_action = 2
			AND	pdt.sub_apply_num = trx.doc_ctrl_num
			AND	pdt.sub_apply_type = trx.trx_type
			AND	#aractcus_work.customer_code = pdt.customer_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 258, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	
	UPDATE	#aractcus_work
	SET	date_last_pyt = arinppyt.date_doc,
		amt_last_pyt = arinppyt.amt_payment,
		last_pyt_doc = arinppyt.doc_ctrl_num,
		last_pyt_cur = arinppyt.nat_cur_code
	FROM	#arinppyt_work arinppyt
	WHERE	arinppyt.batch_code = @batch_ctrl_num
	AND	arinppyt.payment_type = 1
	AND	#aractcus_work.customer_code = arinppyt.customer_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 298, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	UPDATE	#aractcus_work
	SET	date_last_pyt = arinppyt.date_doc,
		amt_last_pyt = arinppyt.amt_payment,
		last_pyt_doc = arinppyt.doc_ctrl_num,
		last_pyt_cur = arinppyt.nat_cur_code
	FROM	#arinppyt_work arinppyt, #arinppdt_work arinppdt
	WHERE	arinppyt.batch_code = @batch_ctrl_num
	AND	arinppyt.trx_ctrl_num = arinppdt.trx_ctrl_num
	AND	arinppyt.trx_type = arinppdt.trx_type
	AND	arinppyt.payment_type = 1
	AND	arinppyt.customer_code != arinppdt.customer_code
	AND	#aractcus_work.customer_code = arinppdt.customer_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 316, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	UPDATE	#aractcus_work
	SET	date_last_pyt = artrx.date_doc,
		amt_last_pyt = artrx.amt_net,
		last_pyt_doc = artrx.doc_ctrl_num,
		last_pyt_cur = artrx.nat_cur_code
	FROM	#arinppyt_work arinppyt, #arinppdt_work arinppdt, #artrx_work artrx
	WHERE	arinppyt.batch_code = @batch_ctrl_num
	AND	arinppyt.trx_ctrl_num = arinppdt.trx_ctrl_num
	AND	arinppdt.trx_type = arinppdt.trx_type
	AND	arinppyt.payment_type = 2		
	AND	arinppyt.doc_ctrl_num = artrx.doc_ctrl_num
	AND	arinppyt.customer_code = artrx.customer_code
	AND	artrx.trx_type = 2111
	AND	artrx.payment_type = 1
	AND	arinppyt.customer_code != arinppdt.customer_code
	AND	#aractcus_work.customer_code = arinppdt.customer_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 338, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	CREATE TABLE #inv_paid_off
	(
		doc_ctrl_num	varchar(16),
		trx_type	int
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 355, 5 ) + " -- EXIT: "
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
	AND	artrxpdt.db_action = 2
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 378, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	CREATE TABLE #invoices_paid
	(
		customer_code		varchar(8),
		num_inv_paid		int,
		num_overdue_pyt	int,
		sum_days_to_pay_off	int,
		sum_days_overdue	int		
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 393, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT	#invoices_paid
	(	
		customer_code,
		num_inv_paid,
		num_overdue_pyt,
		sum_days_to_pay_off,
		sum_days_overdue		
	)
	SELECT
		artrx.customer_code,
		SUM(artrx.paid_flag),
		SUM(SIGN( 1 + SIGN(artrx.date_paid - 0.5 - artrx.date_due)) * artrx.paid_flag),
		SUM(SIGN( 1 + SIGN(artrx.date_paid - artrx.date_doc)) * (artrx.date_paid - artrx.date_doc)),
		SUM(SIGN( 1 + SIGN(artrx.date_paid - artrx.date_due)) * (artrx.date_paid - artrx.date_due))
	FROM	#artrx_work artrx, #inv_paid_off inv
	WHERE	artrx.doc_ctrl_num = inv.doc_ctrl_num
	AND	artrx.trx_type = inv.trx_type	
	GROUP BY artrx.customer_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 417, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #inv_paid_off
			
	UPDATE	#aractcus_work
	SET	num_inv_paid = a.num_inv_paid,
		num_overdue_pyt = a.num_overdue_pyt,
		sum_days_to_pay_off = a.sum_days_to_pay_off,
		sum_days_overdue = a.sum_days_overdue
	FROM	#invoices_paid a
	WHERE	#aractcus_work.customer_code = a.customer_code		
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 435, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #invoices_paid
	
		 
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruca.sp" + ", line " + STR( 442, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCRUpdateCustomerActivity_SP] TO [public]
GO
