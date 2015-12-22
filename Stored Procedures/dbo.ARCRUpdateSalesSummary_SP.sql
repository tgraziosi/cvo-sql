SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCRUpdateSalesSummary_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcruss.sp", 72, "Entering ARCRUpdateSalesSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 75, 5 ) + " -- ENTRY: "
	

	INSERT	#arsumslp_work
	(
		salesperson_code,
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
		inv.salesperson_code,
		glprd.period_start_date,
		glprd.period_end_date,
		COUNT(pdt.amt_applied),
		SUM(ROUND(pdt.amt_applied* ( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)),
		SUM(ROUND(pdt.inv_amt_disc_taken* ( SIGN(1 + SIGN(inv.rate_home))*(inv.rate_home) + (SIGN(ABS(SIGN(ROUND(inv.rate_home,6))))/(inv.rate_home + SIGN(1 - ABS(SIGN(ROUND(inv.rate_home,6)))))) * SIGN(SIGN(inv.rate_home) - 1) ), @home_precision)),
		SUM(ROUND(pdt.inv_amt_wr_off* ( SIGN(1 + SIGN(inv.rate_home))*(inv.rate_home) + (SIGN(ABS(SIGN(ROUND(inv.rate_home,6))))/(inv.rate_home + SIGN(1 - ABS(SIGN(ROUND(inv.rate_home,6)))))) * SIGN(SIGN(inv.rate_home) - 1) ), @home_precision)),
		SUM(ROUND(pdt.amt_applied* ( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision)),
		SUM(ROUND(pdt.inv_amt_disc_taken* ( SIGN(1 + SIGN(inv.rate_oper))*(inv.rate_oper) + (SIGN(ABS(SIGN(ROUND(inv.rate_oper,6))))/(inv.rate_oper + SIGN(1 - ABS(SIGN(ROUND(inv.rate_oper,6)))))) * SIGN(SIGN(inv.rate_oper) - 1) ), @oper_precision)),
		SUM(ROUND(pdt.inv_amt_wr_off* ( SIGN(1 + SIGN(inv.rate_oper))*(inv.rate_oper) + (SIGN(ABS(SIGN(ROUND(inv.rate_oper,6))))/(inv.rate_oper + SIGN(1 - ABS(SIGN(ROUND(inv.rate_oper,6)))))) * SIGN(SIGN(inv.rate_oper) - 1) ), @oper_precision))
	FROM	#arinppyt_work pyt, #artrxpdt_work pdt, glprd, #artrx_work inv
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pyt.non_ar_flag = 0
	AND	glprd.period_start_date <= pyt.date_applied
	AND	glprd.period_end_date >= pyt.date_applied
	AND	pdt.sub_apply_num = inv.doc_ctrl_num
	AND	pdt.sub_apply_type = inv.trx_type
	AND	pdt.db_action = 2
	AND	( LTRIM(inv.salesperson_code) IS NOT NULL AND LTRIM(inv.salesperson_code) != " " )
	GROUP BY inv.salesperson_code, glprd.period_start_date, glprd.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 116, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	CREATE TABLE #invoices_paid
	(
		salesperson_code	varchar(8),
		doc_ctrl_num		varchar(16),
		trx_type		int,
		paid_flag		smallint
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 132, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT	#invoices_paid
	(	
		salesperson_code,
		doc_ctrl_num,
		trx_type,
		paid_flag
	)
	SELECT	DISTINCT
		artrx.salesperson_code,
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
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 158, 5 ) + " -- EXIT: "
		RETURN 34563
	END

			
	UPDATE	#arsumslp_work
	SET	num_inv_paid = 
		(
			SELECT	SUM(paid_flag)
			FROM	#invoices_paid
			WHERE	#invoices_paid.salesperson_code = #arsumslp_work.salesperson_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 175, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #invoices_paid
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 182, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	UPDATE	#arsumslp_work
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
			AND	( LTRIM(invoice.salesperson_code) IS NOT NULL AND LTRIM(invoice.salesperson_code) != " " )
			AND	artrxpdt.db_action = 2
			AND	#arsumslp_work.salesperson_code = invoice.salesperson_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 204, 5 ) + " -- EXIT: "
		RETURN 34563
	END	

	
	UPDATE	#arsumslp_work
	SET	sum_days_overdue =
		(
			SELECT	SUM(arinppyt.date_applied - artrxage.date_due)
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
			AND	arinppyt.date_applied > artrxage.date_due
			AND	( LTRIM(invoice.salesperson_code) IS NOT NULL AND LTRIM(invoice.salesperson_code) != " " )
			AND	artrxpdt.db_action = 2
			AND	#arsumslp_work.salesperson_code = invoice.salesperson_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 245, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#arsumslp_work
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
			AND	arinppyt.date_applied > artrxage.date_due
			AND	( LTRIM(invoice.salesperson_code) IS NOT NULL AND LTRIM(invoice.salesperson_code) != " " )
			AND	artrxpdt.db_action = 2
			AND	#arsumslp_work.salesperson_code = invoice.salesperson_code
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 273, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcruss.sp" + ", line " + STR( 277, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCRUpdateSalesSummary_SP] TO [public]
GO
