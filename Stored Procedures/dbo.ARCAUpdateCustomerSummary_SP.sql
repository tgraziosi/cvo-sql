SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCAUpdateCustomerSummary_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint,
						@perf_level		smallint,
						@home_precision	float,
						@oper_precision	float
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result 		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaucs.sp", 54, "Entering ARCAUpdateCustomerSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaucs.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

	
	INSERT	#arsumcus_work
	(
		customer_code,
		date_from,
		date_thru,
		amt_pyt,
		amt_disc_taken,
		amt_wr_off,
		amt_pyt_oper,
		amt_disc_t_oper,
		amt_wr_off_oper
	)
	SELECT	DISTINCT 
		pdt.customer_code,
		glprd.period_start_date,
		glprd.period_end_date,
		SUM(ROUND(-pdt.amt_applied * ( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ),@home_precision)), 	
		SUM(ROUND(-pdt.amt_disc_taken * ( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)),
		SUM(ROUND(-pdt.amt_max_wr_off * ( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)),	
		SUM(ROUND(-pdt.amt_applied * ( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ),@oper_precision)), 	
		SUM(ROUND(-pdt.amt_disc_taken * ( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision)),
		SUM(ROUND(-pdt.amt_max_wr_off * ( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision))	
	FROM	#arinppyt_work pyt, #arinppdt_work pdt, glprd
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pyt.non_ar_flag = 0
	AND	glprd.period_start_date <= pyt.date_applied
	AND	glprd.period_end_date >= pyt.date_applied
	GROUP BY pdt.customer_code, glprd.period_start_date, glprd.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaucs.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
		RETURN 34563
	END

				
	
	UPDATE	#arsumcus_work
	SET	num_inv_paid = - invoice_pre.num_inv_paid + ISNULL(( 	SELECT SUM(invoice_post.paid_flag)	
										FROM	#artrx_work invoice_post
										WHERE	#arsumcus_work.customer_code = invoice_post.customer_code 
										AND	invoice_post.trx_type <= 2031 ),0.0)
	FROM	#arsumcus_pre	invoice_pre
	WHERE	#arsumcus_work.customer_code = invoice_pre.customer_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaucs.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
		RETURN 34563
	END	
	
	
	UPDATE	#arsumcus_work
	SET	num_nsf = (	SELECT count(a.doc_ctrl_num) 	 
				FROM	#arinppdt_work a
				WHERE	a.temp_flag = 1
				AND	#arsumcus_work.customer_code = a.customer_code
				AND	a.trx_type = 2121
			 )
			 
	UPDATE	#arsumcus_work
	SET	amt_nsf = (	SELECT SUM(ROUND(a.amt_applied * ( SIGN(1 + SIGN(b.rate_home))*(b.rate_home) + (SIGN(ABS(SIGN(ROUND(b.rate_home,6))))/(b.rate_home + SIGN(1 - ABS(SIGN(ROUND(b.rate_home,6)))))) * SIGN(SIGN(b.rate_home) - 1) ), @home_precision)) 
				FROM	#arinppdt_work a, #arinppyt_work b
				WHERE	a.trx_ctrl_num = b.trx_ctrl_num
				AND	a.trx_type = b.trx_type
				AND	b.batch_code = @batch_ctrl_num
				AND	#arsumcus_work.customer_code = a.customer_code
				AND	b.trx_type = 2121
			 )

	UPDATE	#arsumcus_work
	SET	amt_nsf_oper = (	SELECT SUM(ROUND(a.amt_applied * ( SIGN(1 + SIGN(b.rate_oper))*(b.rate_oper) + (SIGN(ABS(SIGN(ROUND(b.rate_oper,6))))/(b.rate_oper + SIGN(1 - ABS(SIGN(ROUND(b.rate_oper,6)))))) * SIGN(SIGN(b.rate_oper) - 1) ), @oper_precision)) 
				FROM	#arinppdt_work a, #arinppyt_work b
				WHERE	a.trx_ctrl_num = b.trx_ctrl_num
				AND	a.trx_type = b.trx_type
				AND	b.batch_code = @batch_ctrl_num
				AND	#arsumcus_work.customer_code = a.customer_code
				AND	b.trx_type = 2121
			 )

	UPDATE	#arsumcus_work
	SET	amt_nsf = ISNULL(amt_nsf,0.0) + 
			 (	SELECT SUM(ROUND(a.amt_on_acct * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @home_precision)) 	 
				FROM	#arinppyt_work a
				WHERE	a.batch_code = @batch_ctrl_num
				AND	#arsumcus_work.customer_code = a.customer_code
				AND	a.trx_type = 2121
			 )

	UPDATE	#arsumcus_work
	SET	amt_nsf_oper = ISNULL(amt_nsf_oper,0.0) + 
			 (	SELECT SUM(ROUND(a.amt_on_acct * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @oper_precision)) 	 
				FROM	#arinppyt_work a
				WHERE	a.batch_code = @batch_ctrl_num
				AND	#arsumcus_work.customer_code = a.customer_code
				AND	a.trx_type = 2121
			 )

		
	INSERT	#arsumcus_work
	(
		customer_code,
		date_from,
		date_thru,
		amt_nsf,
		amt_nsf_oper
	)
	SELECT	DISTINCT 
		pyt.customer_code,
		glprd.period_start_date,
		glprd.period_end_date,
		SUM(ROUND(pyt.amt_on_acct * ( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)),	
		SUM(ROUND(pyt.amt_on_acct * ( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision))	
	FROM	#arinppyt_work pyt, glprd
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.non_ar_flag = 0
	AND	pyt.trx_type = 2121
	AND	glprd.period_start_date <= pyt.date_applied
	AND	glprd.period_end_date >= pyt.date_applied
	AND	pyt.customer_code NOT IN (	
							SELECT customer_code
							FROM	#arsumcus_work
						 )
	GROUP BY pyt.customer_code, glprd.period_start_date, glprd.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaucs.sp" + ", line " + STR( 205, 5 ) + " -- EXIT: "
		RETURN 34563
	END
					
		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaucs.sp" + ", line " + STR( 210, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCAUpdateCustomerSummary_SP] TO [public]
GO
