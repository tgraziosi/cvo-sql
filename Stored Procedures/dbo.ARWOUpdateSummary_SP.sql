SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOUpdateSummary_SP] 	@batch_ctrl_num 	varchar(16),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
AS
DECLARE	@home_prec	smallint,
		@oper_prec	smallint,
		@sumprc	smallint,
		@sumshp	smallint,
		@sumslp	smallint,
		@sumter	smallint

BEGIN 
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 60, 5 ) + " -- MSG: " + "batch_ctrl_num = " + @batch_ctrl_num


	
	SELECT	@sumprc = arsumprc_flag,
		@sumshp = arsumshp_flag,
		@sumslp = arsumslp_flag,
		@sumter = arsumter_flag
	FROM	arco

	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 74, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	SELECT	@home_prec = h.curr_precision,
		@oper_prec = o.curr_precision
	FROM	glco, glcurr_vw h, glcurr_vw o
	WHERE	glco.home_currency = h.currency_code
	AND	glco.oper_currency = o.currency_code

	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 86, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	INSERT #arsumcus_work 
	(
		customer_code, 
		date_from, 
		date_thru,
		amt_wr_off, 
		amt_wr_off_oper,
		num_wr_off,
		update_flag
	) 
	SELECT	inv.customer_code, 
		period_start_date, 
		period_end_date, 
		SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_home))*(inv.rate_home) + (SIGN(ABS(SIGN(ROUND(inv.rate_home,6))))/(inv.rate_home + SIGN(1 - ABS(SIGN(ROUND(inv.rate_home,6)))))) * SIGN(SIGN(inv.rate_home) - 1) ), @home_prec)),
		SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_oper))*(inv.rate_oper) + (SIGN(ABS(SIGN(ROUND(inv.rate_oper,6))))/(inv.rate_oper + SIGN(1 - ABS(SIGN(ROUND(inv.rate_oper,6)))))) * SIGN(SIGN(inv.rate_oper) - 1) ), @oper_prec)),
		count(pdt.trx_type),
		0
	FROM	#artrxpdt_work pdt, #arinppyt_work pyt, glprd, #artrx_work inv
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pdt.trx_type = 2151
	AND	pdt.sub_apply_num = inv.doc_ctrl_num
	AND	pdt.sub_apply_type = inv.trx_type
	AND	glprd.period_start_date <= pyt.date_applied
	AND	glprd.period_end_date >= pyt.date_applied
	GROUP BY inv.customer_code, period_start_date, period_end_date

	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 123, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#arsumcus_work
	SET	update_flag = 1
	FROM	#arsumcus_work a, arsumcus b
	WHERE	a.customer_code = b.customer_code 
	AND	a.date_thru = b.date_thru

	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 135, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF (@debug_level >= 2)
	BEGIN
		SELECT "customer_code= "+customer_code+
		"amt_wr_off= "+STR(amt_wr_off, 10, 2)+
		"amt_wr_off_oper= "+STR(amt_wr_off_oper, 10, 2)+
		"num_wr_off= "+STR(num_wr_off, 4)+
		"update_flag= "+STR(update_flag, 2)
		FROM #arsumcus_work
	END

	
	IF (@sumprc = 1)
	BEGIN
		INSERT #arsumprc_work 
		(
			price_code, 
			date_from, 
			date_thru,
			amt_wr_off, 
			amt_wr_off_oper, 
			num_wr_off,
			update_flag
		) 
		SELECT	inv.price_code, 
			period_start_date, 
			period_end_date, 
			SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_home))*(inv.rate_home) + (SIGN(ABS(SIGN(ROUND(inv.rate_home,6))))/(inv.rate_home + SIGN(1 - ABS(SIGN(ROUND(inv.rate_home,6)))))) * SIGN(SIGN(inv.rate_home) - 1) ), @home_prec)),
			SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_oper))*(inv.rate_oper) + (SIGN(ABS(SIGN(ROUND(inv.rate_oper,6))))/(inv.rate_oper + SIGN(1 - ABS(SIGN(ROUND(inv.rate_oper,6)))))) * SIGN(SIGN(inv.rate_oper) - 1) ), @oper_prec)),
			count( pdt.trx_type ),
			0
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work inv, glprd
		WHERE	pyt.batch_code = @batch_ctrl_num
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.trx_type = 2151
		AND	pdt.sub_apply_num = inv.doc_ctrl_num
		AND	pdt.sub_apply_type = inv.trx_type
		AND	glprd.period_start_date <= pyt.date_applied
		AND	glprd.period_end_date >= pyt.date_applied
		AND	( LTRIM(inv.price_code) IS NOT NULL AND LTRIM(inv.price_code) != " " )
		GROUP BY inv.price_code, period_start_date, period_end_date

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 185, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE #arsumprc_work
		SET update_flag = 1
		FROM #arsumprc_work a, arsumprc b
		WHERE a.price_code = b.price_code 
		AND a.date_thru = b.date_thru

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 197, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		IF (@debug_level >= 2)
		BEGIN
			SELECT "price_code= "+price_code+
			"amt_wr_off= "+STR(amt_wr_off, 10, 2)+
			"amt_wr_off_oper= "+STR(amt_wr_off_oper, 10, 2)+
			"num_wr_off= "+STR(num_wr_off, 4)+
			"update_flag= "+STR(update_flag, 2)
			FROM #arsumprc_work
		END
	END

	
	IF (@sumshp = 1)
	BEGIN
		INSERT #arsumshp_work 
		(
			customer_code, 
			ship_to_code,
			date_from, 
			date_thru,
			amt_wr_off, 
			amt_wr_off_oper,
			num_wr_off,
			update_flag
		) 
		SELECT	inv.customer_code, 
			inv.ship_to_code,
			period_start_date, 
			period_end_date, 
			SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_home))*(inv.rate_home) + (SIGN(ABS(SIGN(ROUND(inv.rate_home,6))))/(inv.rate_home + SIGN(1 - ABS(SIGN(ROUND(inv.rate_home,6)))))) * SIGN(SIGN(inv.rate_home) - 1) ), @home_prec)),
			SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_oper))*(inv.rate_oper) + (SIGN(ABS(SIGN(ROUND(inv.rate_oper,6))))/(inv.rate_oper + SIGN(1 - ABS(SIGN(ROUND(inv.rate_oper,6)))))) * SIGN(SIGN(inv.rate_oper) - 1) ), @oper_prec)),
			count( pdt.trx_type ),
			0
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work inv, glprd
		WHERE	pyt.batch_code = @batch_ctrl_num
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.trx_type = 2151
		AND	pdt.sub_apply_num = inv.doc_ctrl_num
		AND	pdt.sub_apply_type = inv.trx_type
		AND	glprd.period_start_date <= pyt.date_applied
		AND	glprd.period_end_date >= pyt.date_applied
		AND	( LTRIM(inv.ship_to_code) IS NOT NULL AND LTRIM(inv.ship_to_code) != " " )
		GROUP BY inv.customer_code, inv.ship_to_code, period_start_date, period_end_date

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 250, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE #arsumshp_work
		SET update_flag = 1
		FROM #arsumshp_work a, arsumshp b
		WHERE a.customer_code = b.customer_code 
		AND a.ship_to_code = b.ship_to_code
		AND a.date_thru = b.date_thru

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 263, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	IF (@sumslp = 1)
	BEGIN
		INSERT #arsumslp_work 
		(
			salesperson_code, 
			date_from, 
			date_thru,
			amt_wr_off, 
			amt_wr_off_oper, 
			num_wr_off,
			update_flag
		) 
		SELECT	inv.salesperson_code, 
			period_start_date, 
			period_end_date, 
			SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_home))*(inv.rate_home) + (SIGN(ABS(SIGN(ROUND(inv.rate_home,6))))/(inv.rate_home + SIGN(1 - ABS(SIGN(ROUND(inv.rate_home,6)))))) * SIGN(SIGN(inv.rate_home) - 1) ), @home_prec)),
			SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_oper))*(inv.rate_oper) + (SIGN(ABS(SIGN(ROUND(inv.rate_oper,6))))/(inv.rate_oper + SIGN(1 - ABS(SIGN(ROUND(inv.rate_oper,6)))))) * SIGN(SIGN(inv.rate_oper) - 1) ), @oper_prec)),
			count(pdt.trx_type),
			0
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work inv, glprd
		WHERE	pyt.batch_code = @batch_ctrl_num
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.trx_type = 2151
		AND	pdt.sub_apply_num = inv.doc_ctrl_num
		AND	pdt.sub_apply_type = inv.trx_type
		AND	glprd.period_start_date <= pyt.date_applied
		AND	glprd.period_end_date >= pyt.date_applied
		AND	( LTRIM(inv.salesperson_code) IS NOT NULL AND LTRIM(inv.salesperson_code) != " " )
		GROUP BY inv.salesperson_code, period_start_date, period_end_date

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 304, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE #arsumslp_work
		SET update_flag = 1
		FROM #arsumslp_work a, arsumslp b
		WHERE a.salesperson_code = b.salesperson_code 
		AND a.date_thru = b.date_thru

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 316, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	
	IF (@sumter = 1)
	BEGIN
		INSERT #arsumter_work 
		(
			territory_code, 
			date_from, 
			date_thru,
			amt_wr_off, 
			amt_wr_off_oper, 
			num_wr_off,
			update_flag
		) 
		SELECT	inv.territory_code, 
			period_start_date, 
			period_end_date, 
			SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_home))*(inv.rate_home) + (SIGN(ABS(SIGN(ROUND(inv.rate_home,6))))/(inv.rate_home + SIGN(1 - ABS(SIGN(ROUND(inv.rate_home,6)))))) * SIGN(SIGN(inv.rate_home) - 1) ), @home_prec)),
			SUM( ROUND( ( pdt.amt_wr_off ) * ( SIGN(1 + SIGN(inv.rate_oper))*(inv.rate_oper) + (SIGN(ABS(SIGN(ROUND(inv.rate_oper,6))))/(inv.rate_oper + SIGN(1 - ABS(SIGN(ROUND(inv.rate_oper,6)))))) * SIGN(SIGN(inv.rate_oper) - 1) ), @oper_prec)),
			count(pdt.trx_type) num_wroff,
			0
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work inv, glprd
		WHERE	pyt.batch_code = @batch_ctrl_num
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.trx_type = 2151
		AND	pdt.sub_apply_num = inv.doc_ctrl_num
		AND	pdt.sub_apply_type = inv.trx_type
		AND	glprd.period_start_date <= pyt.date_applied
		AND	glprd.period_end_date >= pyt.date_applied
		AND	( LTRIM(inv.territory_code) IS NOT NULL AND LTRIM(inv.territory_code) != " " )
		GROUP BY inv.territory_code, period_start_date, period_end_date

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 357, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE #arsumter_work
		SET update_flag = 1
		FROM #arsumter_work a, arsumter b
		WHERE a.territory_code = b.territory_code 
		AND a.date_thru = b.date_thru
		
		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 369, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwous.sp" + ", line " + STR( 374, 5 ) + " -- EXIT: "
	RETURN 0


END
GO
GRANT EXECUTE ON  [dbo].[ARWOUpdateSummary_SP] TO [public]
GO
