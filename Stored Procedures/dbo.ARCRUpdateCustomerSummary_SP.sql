SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCRUpdateCustomerSummary_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrucs.sp", 71, "Entering ARCRUpdateCustomerSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "
	
	
	INSERT	#arsumcus_work
	(
		customer_code,
		date_from,
		date_thru,
		num_pyt,
		amt_pyt,
		amt_disc_taken,
		amt_wr_off,
		amt_pyt_oper,
		amt_disc_t_oper,
		amt_wr_off_oper
	)
	SELECT 
		pdt.customer_code,
		glprd.period_start_date,
		glprd.period_end_date,
		COUNT(pdt.amt_applied),
		SUM(ROUND(pdt.amt_applied*( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)),
		SUM(ROUND(pdt.inv_amt_disc_taken*( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), @home_precision)),
		SUM(ROUND(pdt.inv_amt_wr_off*( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), @home_precision)),
		SUM(ROUND(pdt.amt_applied*( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision)),
		SUM(ROUND(pdt.inv_amt_disc_taken*( SIGN(1 + SIGN(trx.rate_oper))*(trx.rate_oper) + (SIGN(ABS(SIGN(ROUND(trx.rate_oper,6))))/(trx.rate_oper + SIGN(1 - ABS(SIGN(ROUND(trx.rate_oper,6)))))) * SIGN(SIGN(trx.rate_oper) - 1) ), @oper_precision)),
		SUM(ROUND(pdt.inv_amt_wr_off*( SIGN(1 + SIGN(trx.rate_oper))*(trx.rate_oper) + (SIGN(ABS(SIGN(ROUND(trx.rate_oper,6))))/(trx.rate_oper + SIGN(1 - ABS(SIGN(ROUND(trx.rate_oper,6)))))) * SIGN(SIGN(trx.rate_oper) - 1) ), @oper_precision))
	FROM	#arinppyt_work pyt, #artrxpdt_work pdt, glprd, #artrx_work trx
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pyt.non_ar_flag = 0
	AND	pdt.sub_apply_num = trx.doc_ctrl_num
	AND	pdt.sub_apply_type = trx.trx_type
	AND	glprd.period_start_date <= pyt.date_applied
	AND	glprd.period_end_date >= pyt.date_applied
	AND	pdt.db_action = 2
	GROUP BY pdt.customer_code, glprd.period_start_date, glprd.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 114, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	CREATE TABLE #invoices_paid
	(
		customer_code	varchar(8),
		doc_ctrl_num	varchar(16),
		trx_type	int,
		paid_flag	smallint
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 130, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT	#invoices_paid
	(	
		customer_code,
		doc_ctrl_num,
		trx_type,
		paid_flag
	)
	SELECT	DISTINCT
		artrxpdt.customer_code,
		artrx.doc_ctrl_num,
		artrx.trx_type,
		artrx.paid_flag
	FROM	#arinppyt_work arinppyt, #artrxpdt_work artrxpdt, #artrx_work artrx
	WHERE	arinppyt.trx_ctrl_num = artrxpdt.trx_ctrl_num 
	AND	arinppyt.trx_type = artrxpdt.trx_type
	AND	arinppyt.batch_code = @batch_ctrl_num
	AND	artrxpdt.sub_apply_num = artrx.doc_ctrl_num
	AND	artrxpdt.sub_apply_type = artrx.trx_type
	AND	artrx.trx_type <= 2031 
	AND	artrxpdt.db_action = 2
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 156, 5 ) + " -- EXIT: "
		RETURN 34563
	END

			
	UPDATE	#arsumcus_work
	SET	num_inv_paid = 
		(
			SELECT	SUM(paid_flag)
			FROM	#invoices_paid
			WHERE	#invoices_paid.customer_code = #arsumcus_work.customer_code
			GROUP BY #invoices_paid.customer_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 174, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #invoices_paid
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 181, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	UPDATE	#arsumcus_work
	SET	sum_days_to_pay_off = 
		(
			SELECT	SUM(arinppyt.date_applied - invoice.date_doc)
			FROM	#arinppyt_work arinppyt, #artrxpdt_work artrxpdt, #artrx_work invoice
			WHERE	arinppyt.batch_code = @batch_ctrl_num
			AND	arinppyt.trx_ctrl_num = artrxpdt.trx_ctrl_num
			AND	arinppyt.trx_type = artrxpdt.trx_type
			AND	artrxpdt.sub_apply_num = invoice.doc_ctrl_num
			AND	artrxpdt.sub_apply_type = invoice.trx_type
			AND	invoice.paid_flag = 1
			AND	arinppyt.date_applied > invoice.date_doc
			AND	artrxpdt.db_action = 2
			AND	#arsumcus_work.customer_code = artrxpdt.customer_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 202, 5 ) + " -- EXIT: "
		RETURN 34563
	END	

	
	UPDATE	#arsumcus_work
	SET	sum_days_overdue =
		(
			SELECT	SUM(artrxpdt.date_applied - artrxage.date_due)
			FROM	#arinppyt_work arinppyt, #artrxpdt_work artrxpdt, #artrx_work invoice, #artrxage_work artrxage
			WHERE	arinppyt.batch_code = @batch_ctrl_num
			AND	arinppyt.trx_ctrl_num = artrxpdt.trx_ctrl_num
			AND	arinppyt.trx_type = artrxpdt.trx_type
			AND	artrxpdt.sub_apply_num = invoice.doc_ctrl_num
			AND	artrxpdt.sub_apply_type = invoice.trx_type
			AND	invoice.paid_flag = 1
			AND	artrxage.doc_ctrl_num = artrxpdt.sub_apply_num
			AND	artrxage.trx_type = artrxpdt.sub_apply_type
			AND	artrxage.date_aging = artrxpdt.date_aging
			AND	artrxpdt.date_applied > artrxage.date_due
			AND	artrxpdt.db_action = 2
			AND	#arsumcus_work.customer_code = artrxpdt.customer_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 246, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#arsumcus_work
	SET	num_overdue_pyt = 
		(
			SELECT	COUNT(artrxpdt.apply_to_num)
			FROM	#arinppyt_work arinppyt, #artrxpdt_work artrxpdt, #artrx_work invoice, #artrxage_work artrxage
			WHERE	arinppyt.batch_code = @batch_ctrl_num
			AND	arinppyt.trx_ctrl_num = artrxpdt.trx_ctrl_num
			AND	arinppyt.trx_type = artrxpdt.trx_type
			AND	artrxpdt.sub_apply_num = invoice.doc_ctrl_num
			AND	artrxpdt.sub_apply_type = invoice.trx_type
			AND	invoice.paid_flag = 1
			AND	artrxage.doc_ctrl_num = artrxpdt.sub_apply_num
			AND	artrxage.trx_type = artrxpdt.sub_apply_type
			AND	artrxage.date_aging = artrxpdt.date_aging
			AND	artrxpdt.date_applied > artrxage.date_due
			AND	artrxpdt.db_action = 2
			AND	#arsumcus_work.customer_code = artrxpdt.customer_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 273, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level >= 2 )
	BEGIN
		SELECT "dumping #arsumcus_work...."
		SELECT "customer_code = " + customer_code +
			"date_from = " + STR(date_from, 8) +
			"amt_pyt = " + STR(amt_pyt, 10, 2) +
			"amt_disc_taken = " + STR(amt_disc_taken, 10, 2) +
			"amt_wr_off = " + STR(amt_wr_off, 10, 2) +
			"num_inv_paid = " + STR(num_inv_paid, 6)
		FROM	#arsumcus_work
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrucs.sp" + ", line " + STR( 289, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCRUpdateCustomerSummary_SP] TO [public]
GO
