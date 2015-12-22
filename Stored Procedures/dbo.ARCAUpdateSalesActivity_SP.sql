SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCAUpdateSalesActivity_SP]		@batch_ctrl_num	varchar( 16 ),
							@debug_level		smallint = 0,
							@perf_level		smallint = 0,
							@home_precision	float,
							@oper_precision	float	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									








DECLARE
	@result 		int, 
	@process_ctrl_num	varchar( 16),
	@user_id		smallint,
	@date_entered		int,
	@period_end		int,
	@batch_type		smallint,
	@max_trx_ctrl_num	varchar( 16)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcausa.sp", 57, "Entering ARCAUpdateSalesActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "


	
	CREATE TABLE	#max_trx
			(
				character_8		varchar(8),
				trx_ctrl_num		varchar(16)
			)
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 98, 5 ) + " -- EXIT: "
				RETURN 34563
			END

	
	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@user_id OUTPUT,
					@date_entered OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 115, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	
	INSERT #aractslp_work
	(	
		salesperson_code
	)
	SELECT	DISTINCT trx.salesperson_code
	FROM	#arinppdt_work pdt, #artrx_work trx
	WHERE	pdt.temp_flag = 1
	AND	pdt.sub_apply_num = trx.doc_ctrl_num
	AND	pdt.sub_apply_type = trx.trx_type
	AND	( LTRIM(trx.salesperson_code) IS NOT NULL AND LTRIM(trx.salesperson_code) != " " )
				IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 132, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		

	INSERT	#max_trx (character_8, trx_ctrl_num)
	SELECT	trx.salesperson_code,				 
		MAX(pdt.trx_ctrl_num)
	FROM	#arinppdt_work pdt, #artrx_work trx
	WHERE	pdt.sub_apply_num = trx.doc_ctrl_num
	AND	pdt.sub_apply_type = trx.trx_type
	AND	pdt.temp_flag = 1
	AND	pdt.trx_type = 2121
	AND	( LTRIM(trx.salesperson_code) IS NOT NULL AND LTRIM(trx.salesperson_code) != " " )
	GROUP BY trx.salesperson_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 150, 5 ) + " -- EXIT: "
		RETURN 34563
	END

		
	
	SELECT	artrx.salesperson_code, pdt.trx_ctrl_num, SUM(pdt.amt_applied) sum_amt_applied
	INTO	#t
	FROM	#max_trx trx, #arinppdt_work pdt, #artrx_work artrx
	WHERE	trx.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pdt.trx_type = 2121
	AND	pdt.sub_apply_num = artrx.doc_ctrl_num
	AND	pdt.sub_apply_type = artrx.trx_type
	AND	trx.character_8 = artrx.salesperson_code
	GROUP BY artrx.salesperson_code, pdt.trx_ctrl_num
		
	UPDATE #aractslp_work
	SET	date_last_nsf = @date_entered,
		amt_last_nsf = #t.sum_amt_applied,
		last_nsf_doc = pyt.doc_ctrl_num,
		last_nsf_cur = pyt.nat_cur_code
	FROM	#t, #arinppyt_work pyt
	WHERE	#aractslp_work.salesperson_code = #t.salesperson_code
	AND	#t.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pyt.trx_type = 2121
	
		
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 181, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractslp_work
	SET	amt_balance = 
		(
			SELECT	SUM(
				ROUND(	(	pdt.inv_amt_applied 
					+	pdt.inv_amt_disc_taken 
					+	pdt.inv_amt_max_wr_off
					) 
					* ( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ),@home_precision)
					)
			FROM	#arinppyt_work pyt, #arinppdt_work pdt, #artrx_work trx
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	pdt.sub_apply_num = trx.doc_ctrl_num
			AND	pdt.sub_apply_type = trx.trx_type
			AND	#aractslp_work.salesperson_code = trx.salesperson_code
			AND	pyt.non_ar_flag = 0
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 209, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	UPDATE	#aractslp_work
	SET	amt_balance_oper = 
		(
			SELECT	SUM(
				ROUND(	(	pdt.inv_amt_applied 
					+	pdt.inv_amt_disc_taken 
					+	pdt.inv_amt_max_wr_off
					) 
					* ( SIGN(1 + SIGN(trx.rate_oper))*(trx.rate_oper) + (SIGN(ABS(SIGN(ROUND(trx.rate_oper,6))))/(trx.rate_oper + SIGN(1 - ABS(SIGN(ROUND(trx.rate_oper,6)))))) * SIGN(SIGN(trx.rate_oper) - 1) ),@oper_precision)
					)
			FROM	#arinppyt_work pyt, #arinppdt_work pdt, #artrx_work trx
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	pdt.sub_apply_num = trx.doc_ctrl_num
			AND	pdt.sub_apply_type = trx.trx_type
			AND	#aractslp_work.salesperson_code = trx.salesperson_code
			AND	pyt.non_ar_flag = 0
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 234, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	
		
	UPDATE	#aractslp_work
	SET	num_inv_paid = - invoice_pre.num_inv_paid + ISNULL(( 	SELECT SUM(invoice_post.paid_flag)	
										FROM	#artrx_work invoice_post
										WHERE	#aractslp_work.salesperson_code = invoice_post.salesperson_code 
										AND	invoice_post.trx_type <= 2031 ),0.0)
	FROM	#arsumslp_pre	invoice_pre
	WHERE	#aractslp_work.salesperson_code = invoice_pre.salesperson_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 250, 5 ) + " -- EXIT: "
		RETURN 34563
	END	
	

	IF(@debug_level > 0)
	BEGIN
		SELECT "dumping #aractslp_work after update"
		SELECT	"salesperson_code = " + salesperson_code +
			" date_last_nsf = " + STR(date_last_nsf,8) +
			" amt_last_nsf = " + STR(amt_last_nsf,10,2) +
			" last_nsf_doc = " + last_nsf_doc +
			" last_nsf_cur = " + last_nsf_cur +
			" amt_balance = " + STR(amt_balance,10,2) +
			" amt_balance_oper = " + STR(amt_balance_oper,10,2)
		FROM	#aractslp_work
	END

	DROP TABLE #max_trx
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausa.sp" + ", line " + STR( 270, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCAUpdateSalesActivity_SP] TO [public]
GO
