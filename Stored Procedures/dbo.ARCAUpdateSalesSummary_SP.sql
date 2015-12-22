SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCAUpdateSalesSummary_SP]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcauss.sp", 55, "Entering ARCAUpdateSalesSummary_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcauss.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

	
	INSERT	#arsumslp_work
	(
		salesperson_code,
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
		trx.salesperson_code,
		glprd.period_start_date,
		glprd.period_end_date,
		SUM(ROUND(-pdt.amt_applied * ( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ),@home_precision)), 	
		SUM(ROUND(-pdt.amt_disc_taken * ( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)),
		SUM(ROUND(-pdt.amt_max_wr_off * ( SIGN(1 + SIGN(pyt.rate_home))*(pyt.rate_home) + (SIGN(ABS(SIGN(ROUND(pyt.rate_home,6))))/(pyt.rate_home + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_home,6)))))) * SIGN(SIGN(pyt.rate_home) - 1) ), @home_precision)),	
		SUM(ROUND(-pdt.amt_applied * ( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ),@oper_precision)), 	
		SUM(ROUND(-pdt.amt_disc_taken * ( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision)),
		SUM(ROUND(-pdt.amt_max_wr_off * ( SIGN(1 + SIGN(pyt.rate_oper))*(pyt.rate_oper) + (SIGN(ABS(SIGN(ROUND(pyt.rate_oper,6))))/(pyt.rate_oper + SIGN(1 - ABS(SIGN(ROUND(pyt.rate_oper,6)))))) * SIGN(SIGN(pyt.rate_oper) - 1) ), @oper_precision))	
	FROM	#arinppyt_work pyt, #arinppdt_work pdt, #artrx_work trx, glprd
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pyt.non_ar_flag = 0
	AND	glprd.period_start_date <= pyt.date_applied
	AND	glprd.period_end_date >= pyt.date_applied
	AND	pdt.sub_apply_num = trx.doc_ctrl_num
	AND	pdt.sub_apply_type = trx.trx_type
	AND	( LTRIM(salesperson_code) IS NOT NULL AND LTRIM(salesperson_code) != " " )
	GROUP BY trx.salesperson_code, glprd.period_start_date, glprd.period_end_date
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcauss.sp" + ", line " + STR( 104, 5 ) + " -- EXIT: "
		RETURN 34563
	END

				
	


	UPDATE	#arsumslp_work
	SET	num_inv_paid = - invoice_pre.num_inv_paid + ISNULL(( 	SELECT SUM(invoice_post.paid_flag)	
										FROM	#artrx_work invoice_post
										WHERE	#arsumslp_work.salesperson_code = invoice_post.salesperson_code 
										AND	invoice_post.trx_type <= 2031 ),0.0)
	FROM	#arsumslp_pre	invoice_pre
	WHERE	#arsumslp_work.salesperson_code = invoice_pre.salesperson_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcauss.sp" + ", line " + STR( 126, 5 ) + " -- EXIT: "
		RETURN 34563
	END	
	
	
	UPDATE	#arsumslp_work
	SET	num_nsf = (	SELECT count(b.doc_ctrl_num) 	 
				FROM	#arinppdt_work b, #artrx_work c
				WHERE	b.temp_flag = 1
				AND	b.sub_apply_num = c.doc_ctrl_num
				AND	b.sub_apply_type = c.trx_type
				AND	#arsumslp_work.salesperson_code = c.salesperson_code
				AND	b.trx_type = 2121
			 )
			 
	UPDATE	#arsumslp_work
	SET	amt_nsf = (	SELECT SUM(ROUND(a.amt_applied * ( SIGN(1 + SIGN(c.rate_home))*(c.rate_home) + (SIGN(ABS(SIGN(ROUND(c.rate_home,6))))/(c.rate_home + SIGN(1 - ABS(SIGN(ROUND(c.rate_home,6)))))) * SIGN(SIGN(c.rate_home) - 1) ), @home_precision)) 	 
				FROM	#arinppdt_work a, #arinppyt_work c, #artrx_work b
				WHERE	a.trx_ctrl_num = c.trx_ctrl_num
				AND	a.trx_type = c.trx_type
				AND	c.batch_code = @batch_ctrl_num
				AND	a.sub_apply_num = b.doc_ctrl_num
				AND	a.sub_apply_type = b.trx_type
				AND	#arsumslp_work.salesperson_code = b.salesperson_code
				AND	a.trx_type = 2121
			 )

	UPDATE	#arsumslp_work
	SET	amt_nsf_oper = (	SELECT SUM(ROUND(a.amt_applied * ( SIGN(1 + SIGN(c.rate_oper))*(c.rate_oper) + (SIGN(ABS(SIGN(ROUND(c.rate_oper,6))))/(c.rate_oper + SIGN(1 - ABS(SIGN(ROUND(c.rate_oper,6)))))) * SIGN(SIGN(c.rate_oper) - 1) ), @oper_precision)) 	 
				FROM	#arinppdt_work a, #arinppyt_work c, #artrx_work b
				WHERE	a.trx_ctrl_num = c.trx_ctrl_num
				AND	a.trx_type = c.trx_type
				AND	c.batch_code = @batch_ctrl_num
				AND	a.sub_apply_num = b.doc_ctrl_num
				AND	a.sub_apply_type = b.trx_type
				AND	#arsumslp_work.salesperson_code = b.salesperson_code
				AND	a.trx_type = 2121
			 )
					
		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcauss.sp" + ", line " + STR( 169, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCAUpdateSalesSummary_SP] TO [public]
GO
