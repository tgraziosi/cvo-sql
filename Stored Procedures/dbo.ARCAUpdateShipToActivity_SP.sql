SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCAUpdateShipToActivity_SP]		@batch_ctrl_num	varchar( 16 ),
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

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcausta.sp", 57, "Entering ARCAUpdateShipToActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "

	
	CREATE TABLE	#max_trx
			(
				customer_code		varchar(8),
				ship_to_code		varchar(8),
				trx_ctrl_num		varchar(16)
			)
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 98, 5 ) + " -- EXIT: "
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
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 115, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	
	INSERT #aractshp_work
	(	
		trx.customer_code,
		trx.ship_to_code
	)
	SELECT	DISTINCT trx.customer_code, trx.ship_to_code
	FROM	#arinppdt_work pdt, #artrx_work trx
	WHERE	pdt.temp_flag = 1
	AND	pdt.sub_apply_num = trx.doc_ctrl_num
	AND	pdt.sub_apply_type = trx.trx_type
	AND	( LTRIM(trx.ship_to_code) IS NOT NULL AND LTRIM(trx.ship_to_code) != " " )
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 133, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		

	INSERT	#max_trx 
	SELECT	trx.customer_code,
		trx.ship_to_code,				 
		MAX(pdt.trx_ctrl_num)
	FROM	#arinppdt_work pdt, #artrx_work trx
	WHERE	pdt.sub_apply_num = trx.doc_ctrl_num
	AND	pdt.sub_apply_type = trx.trx_type
	AND	pdt.temp_flag = 1
	AND	pdt.trx_type = 2121
	AND	( LTRIM(trx.ship_to_code) IS NOT NULL AND LTRIM(trx.ship_to_code) != " " )
	GROUP BY trx.customer_code, trx.ship_to_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 152, 5 ) + " -- EXIT: "
		RETURN 34563
	END

		
	
	SELECT	artrx.customer_code, artrx.ship_to_code, pdt.trx_ctrl_num, SUM(pdt.amt_applied) sum_amt_applied
	INTO	#t
	FROM	#max_trx trx, #arinppdt_work pdt, #artrx_work artrx
	WHERE	trx.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pdt.trx_type = 2121
	AND	pdt.sub_apply_num = artrx.doc_ctrl_num
	AND	pdt.sub_apply_type = artrx.trx_type
	AND	trx.customer_code = artrx.customer_code
	AND	trx.ship_to_code = artrx.ship_to_code
	GROUP BY artrx.customer_code, artrx.ship_to_code, pdt.trx_ctrl_num
		
	UPDATE #aractshp_work
	SET	date_last_nsf = @date_entered,
		amt_last_nsf = #t.sum_amt_applied,
		last_nsf_doc = pyt.doc_ctrl_num,
		last_nsf_cur = pyt.nat_cur_code
	FROM	#t, #arinppyt_work pyt
	WHERE	#aractshp_work.ship_to_code = #t.ship_to_code
	AND	#aractshp_work.customer_code = #t.customer_code
	AND	#t.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pyt.trx_type = 2121
	
		
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 185, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#aractshp_work
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
			AND	#aractshp_work.customer_code = trx.customer_code
			AND	#aractshp_work.ship_to_code = trx.ship_to_code
			AND	pyt.non_ar_flag = 0
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 214, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	UPDATE	#aractshp_work
	SET	amt_balance_oper = 
		(
			SELECT	SUM(
				ROUND(	(	pdt.inv_amt_applied 
					+	pdt.inv_amt_disc_taken 
					+	pdt.inv_amt_max_wr_off
					) 
					* ( SIGN(1 + SIGN(trx.rate_oper))*(trx.rate_oper) + (SIGN(ABS(SIGN(ROUND(trx.rate_oper,6))))/(trx.rate_oper + SIGN(1 - ABS(SIGN(ROUND(trx.rate_oper,6)))))) * SIGN(SIGN(trx.rate_oper) - 1) ), @oper_precision)
					)
			FROM	#arinppyt_work pyt, #arinppdt_work pdt, #artrx_work trx
			WHERE	pyt.batch_code = @batch_ctrl_num
			AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
			AND	pyt.trx_type = pdt.trx_type
			AND	pdt.sub_apply_num = trx.doc_ctrl_num
			AND	pdt.sub_apply_type = trx.trx_type
			AND	#aractshp_work.customer_code = trx.customer_code
			AND	#aractshp_work.ship_to_code = trx.ship_to_code
			AND	pyt.non_ar_flag = 0
		)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 240, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	UPDATE	#aractshp_work
	SET	num_inv_paid = - invoice_pre.num_inv_paid + ISNULL(( 	SELECT SUM(invoice_post.paid_flag)	
										FROM	#artrx_work invoice_post
										WHERE	#aractshp_work.ship_to_code = invoice_post.ship_to_code
										AND	#aractshp_work.customer_code = invoice_post.customer_code 
										AND	invoice_post.trx_type <= 2031 ),0.0)
	FROM	#arsumshp_pre	invoice_pre
	WHERE	#aractshp_work.ship_to_code = invoice_pre.ship_to_code
	AND	#aractshp_work.customer_code = invoice_pre.customer_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 257, 5 ) + " -- EXIT: "
		RETURN 34563
	END	
	

	IF(@debug_level > 0)
	BEGIN
		SELECT "dumping #aractshp_work after update"
		SELECT	"ship_to_code = " + ship_to_code +
			" date_last_nsf = " + STR(date_last_nsf,8) +
			" amt_last_nsf = " + STR(amt_last_nsf,10,2) +
			" last_nsf_doc = " + last_nsf_doc +
			" last_nsf_cur = " + last_nsf_cur +
			" amt_balance = " + STR(amt_balance,10,2) +
			" amt_balance_oper = " + STR(amt_balance_oper,10,2)
		FROM	#aractshp_work
	END

	DROP TABLE #max_trx
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcausta.sp" + ", line " + STR( 277, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCAUpdateShipToActivity_SP] TO [public]
GO
