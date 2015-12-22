SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLApplyLTEcharges_SP]	@batch_ctrl_num	varchar( 16 ),
					@date_applied		int,
					@home_currency	varchar( 8 ),
					@oper_currency	varchar( 8 ),
					@user_id		int,
					@debug_level		smallint = 0,
					@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									













DECLARE
 	@result	int,
	@today		int


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflalte.sp", 66, "Entering ARFLApplyLTEcharges_SP", @PERF_time_last OUTPUT
	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 68, 5 ) + " -- MSG: " + "Applying late charges..."
		
	
	EXEC appdate_sp @today OUTPUT

	CREATE TABLE #rates 
	(
		from_currency 	varchar( 8 ),
	 	to_currency 		varchar( 8 ),
	 	rate_type 		varchar( 8 ),
	 	date_applied 		int,
	 	rate 			float
	)
		
	IF( @@error != 0 )
	BEGIN
	 IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 86, 5 ) + " -- MSG: " + "Can't create #rates"
	 	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 87, 5 ) + " -- EXIT: "
	 	RETURN 34563
	END
		
 	
	INSERT	#rates
	SELECT DISTINCT nat_cur_code, @home_currency, rate_type_home, @date_applied, 0.0
	FROM	#cust_info
	WHERE	late_chg_type = 2
			
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 101, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	EXEC @result = CVO_Control..mcrates_sp 
	
	IF (@result != 0)
		RETURN @result 
		 
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping #rates.." 
		SELECT	"from_currency = " + from_currency +
			"rate_type = " + rate_type +
			"date_applied = " + STR(date_applied, 8) +
			"rate = " + STR(rate, 10, 2 )
		FROM	#rates
	END
	
	
	INSERT	#artrx_work
		(
			doc_ctrl_num, 		trx_ctrl_num,			apply_to_num,
			apply_trx_type, 		order_ctrl_num, 		doc_desc,
			batch_code,	 		trx_type,	 		date_entered,
			date_posted,			date_applied,			date_doc,		
			date_shipped,			date_required,		date_due,
			date_aging,		 	customer_code,		ship_to_code,
			salesperson_code,		territory_code,		comment_code,
			fob_code,			freight_code,	 		terms_code,
			fin_chg_code,	 		price_code,	 		dest_zone_code,
			posting_code,			recurring_flag, 		recurring_code,
			tax_code,	 		payment_code,	 		payment_type,	 
			cust_po_num,			non_ar_flag,			gl_acct_code,	 
			gl_trx_id,			prompt1_inp,			prompt2_inp,
			prompt3_inp,			prompt4_inp,			deposit_num,
			amt_gross,			
			amt_freight,			amt_tax,
			amt_discount,			amt_paid_to_date,	 	
			amt_net,		 
			amt_on_acct,			amt_cost,			
			amt_tot_chg,		 
			amt_discount_taken,		amt_write_off_given,		user_id,
			void_flag,		 	paid_flag,	 		date_paid,
			posted_flag,			commission_flag,		cash_acct_code,
			non_ar_doc_num,		purge_flag,			db_action,
			nat_cur_code,			rate_type_home,
			rate_type_oper,		rate_home,			rate_oper,
			amt_tax_included,	org_id
		)
	SELECT		" ",				" ",				" ",
			2071, 		" ",				" ",
			" ",	 			2071,	 	@today,
			@today,			@date_applied,		@date_applied,		
			0,				0,				cust.min_date_due,
			@date_applied, 		cust.customer_code,		" ",
			" ",				" ",				" ",
			" ",				" ",	 			" ",
			cust.fin_chg_code,	 	" ",	 			" ",
			cust.posting_code,		0, 				" ",	
			" ",	 			" ",	 			0,	 
			" ",				0,				" ",	 
			" ",				" ",				" ",
			" ",			" ",				" ",
			ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(rate))*(rate) + (SIGN(ABS(SIGN(ROUND(rate,6))))/(rate + SIGN(1 - ABS(SIGN(ROUND(rate,6)))))) * SIGN(SIGN(rate) - 1) ), gl.curr_precision), 			
			0.0,				0.0,
			0.0,				0.0,	 	
			ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(rate))*(rate) + (SIGN(ABS(SIGN(ROUND(rate,6))))/(rate + SIGN(1 - ABS(SIGN(ROUND(rate,6)))))) * SIGN(SIGN(rate) - 1) ), gl.curr_precision), 	 
			0.0,				0.0,
			ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(rate))*(rate) + (SIGN(ABS(SIGN(ROUND(rate,6))))/(rate + SIGN(1 - ABS(SIGN(ROUND(rate,6)))))) * SIGN(SIGN(rate) - 1) ), gl.curr_precision), 	 
			0.0,				0.0,				@user_id,
			0,		 		0,	 			0,
			1,				0,				" ",
			" ",				0,				2,
			cust.nat_cur_code,		cust.rate_type_home,
			cust.rate_type_oper,		rate.rate,		0,
			0.0,			""
	FROM	arfinchg fin, #cust_info cust, glcurr_vw gl, #rates rate
	WHERE	cust.fin_chg_code = fin.fin_chg_code
	AND	cust.late_chg_type = 2 
	AND	cust.nat_cur_code = gl.currency_code
	AND	cust.nat_cur_code = rate.from_currency
	AND	cust.rate_type_home = rate.rate_type
	AND	((cust.overdue_amt) > (0.0) + 0.0000001) 
	AND	fin.late_chg_amt > 0.0

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 196, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping late charges in #artrx_work after PER CUSTOMER"
		SELECT	"trx_type = " + STR(trx_type, 7) +
			"customer_code = " + customer_code +
			"rate_home = " + STR(rate_home, 10, 2) +
			"amt_net = " + STR(amt_net, 10, 2)
		FROM	#artrx_work
		WHERE	trx_type = 2071
	END
		
	
	DELETE	#rates
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 218, 5 ) + " -- EXIT: "
		RETURN 34563
	END
		
	
	INSERT	#rates
	SELECT DISTINCT nat_cur_code, @oper_currency, rate_type_oper, @date_applied, 0.0
	FROM	#cust_info
	WHERE	late_chg_type = 2
					
	EXEC @result = CVO_Control..mcrates_sp 
		
	IF (@result != 0)
		RETURN @result 
		
	UPDATE	#artrx_work
	SET	rate_oper = rate.rate
	FROM	#cust_info cust, #rates rate
	WHERE	#artrx_work.customer_code = cust.customer_code
	AND	cust.nat_cur_code = rate.from_currency
	AND	cust.rate_type_oper = rate.rate_type
		
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping all #artrx_work.." 
		SELECT	"customer_code = " + customer_code +
			"doc_ctrl_num = " + doc_ctrl_num +
			"apply_to_num = " + apply_to_num +
			"amt_tot_chg = " + STR(amt_tot_chg, 10, 2) +
			"amt_paid_to_date = " + STR(amt_paid_to_date, 10, 2 ) +
			"date_due = " + STR(date_due, 8) +
			"db_action = " + STR(db_action, 2)
		FROM	#artrx_work
	END
	
	
	INSERT	#artrx_work
	(
		doc_ctrl_num, 		trx_ctrl_num,			apply_to_num,
		apply_trx_type, 		order_ctrl_num, 		doc_desc,
		batch_code,	 		trx_type,	 		date_entered,
		date_posted,			date_applied,			date_doc,		
		date_shipped,			date_required,		date_due,
		date_aging,		 	customer_code,		ship_to_code,
		salesperson_code,		territory_code,		comment_code,
		fob_code,			freight_code,	 		terms_code,
		fin_chg_code,	 		price_code,	 		dest_zone_code,
		posting_code,			recurring_flag, 		recurring_code,
		tax_code,	 		payment_code,	 		payment_type,	 
		cust_po_num,			non_ar_flag,			gl_acct_code,	 
		gl_trx_id,			prompt1_inp,			prompt2_inp,
		prompt3_inp,			prompt4_inp,			deposit_num,
		amt_gross,			
		amt_freight,			amt_tax,
		amt_discount,			amt_paid_to_date,	 	
		amt_net,		 
		amt_on_acct,			amt_cost,			
		amt_tot_chg,		 
		amt_discount_taken,		amt_write_off_given,		user_id,
		void_flag,		 	paid_flag,	 		date_paid,
		posted_flag,			commission_flag,		cash_acct_code,
		non_ar_doc_num,		purge_flag,			db_action,
		nat_cur_code,			rate_type_home,
		rate_type_oper,		rate_home,			rate_oper,
		amt_tax_included,	org_id
 	)
 	SELECT	" ",				" ",				trx.doc_ctrl_num,
 		trx.trx_type,			trx.order_ctrl_num,		trx.doc_desc,
 		" ",	 			2071,	 	@today,
 		@today,			@date_applied,		@date_applied,		
 		0,				0,				trx.date_due,
 		trx.date_aging,		trx.customer_code,		trx.ship_to_code,
 		trx.salesperson_code,	trx.territory_code,		trx.comment_code,
 		trx.fob_code,			" ",	 	" ",
 		trx.fin_chg_code,	 	trx.price_code,	 	" ",
 		trx.posting_code,		0, 				" ",	
 		" ",	 			" ",	 			0,	 
 		" ",				0,				gl_acct_code,	 
 		" ",				" ",				" ",
 		" "	,			" ",				" ",
 		ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), gl.curr_precision), 			
 		0.0,				0.0,
 		0.0,				0.0,	 	
 		ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), gl.curr_precision), 	 
 		0.0,			 	0.0,				
 		ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), gl.curr_precision), 	 
 		0.0,				0.0,				@user_id,
 		0,		 		0,	 			0,
 		1,				0,				" ",
 		" ",				0,				2,
 		trx.nat_cur_code,		trx.rate_type_home,
 		trx.rate_type_oper,		trx.rate_home,		trx.rate_oper,
		0.0,					trx.org_id
 	FROM	#artrx_work trx, arfinchg fin, #cust_info cust, glcurr_vw gl
 	WHERE	trx.fin_chg_code = fin.fin_chg_code
 	AND	trx.customer_code = cust.customer_code
 	AND	cust.late_chg_type = 0 	
 	AND	trx.nat_cur_code = gl.currency_code
	AND	trx.apply_to_num = trx.doc_ctrl_num
	AND	trx.apply_trx_type = trx.trx_type
	AND	fin.late_chg_amt > 0.0
	AND	((trx.amt_tot_chg) > (trx.amt_paid_to_date) + 0.0000001)
	AND	trx.date_due < @date_applied
 
 	IF( @@error != 0 )
 	BEGIN
 		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 328, 5 ) + " -- EXIT: "
 		RETURN 34563
 	END
		
 	IF ( @debug_level > 0 )
 	BEGIN
 		SELECT "dumping late charges in #artrx_work after PER INVOICE"
 		SELECT	"trx_type = " + STR(trx_type, 7) +
 			"customer_code = " + customer_code +
 			"apply_to_num = " +apply_to_num +
 			"rate_home = " + STR(rate_home, 10, 2) +
 			"amt_net = " + STR(amt_net, 10, 2)
 		FROM	#artrx_work
 		WHERE	trx_type = 2071
 	END
		
 	
 	UPDATE	#artrx_work
 	SET	temp_flag = 1
 	FROM	#prev_charges chg
 	WHERE	chg.trx_type = 2071
 	AND	chg.apply_to_num = #artrx_work.doc_ctrl_num
 	AND	chg.apply_trx_type = #artrx_work.trx_type
		
 	IF( @@error != 0 )
 	BEGIN
 		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 356, 5 ) + " -- EXIT: "
 		RETURN 34563
 	END
		
 	
 	INSERT	#artrx_work
 	(
 		doc_ctrl_num, 		trx_ctrl_num,			apply_to_num,
 		apply_trx_type, 		order_ctrl_num, 		doc_desc,
 		batch_code,	 		trx_type,	 		date_entered,
 		date_posted,			date_applied,			date_doc,		
 		date_shipped,			date_required,		date_due,
 		date_aging,		 	customer_code,		ship_to_code,
 		salesperson_code,		territory_code,		comment_code,
 		fob_code,			freight_code,	 		terms_code,
 		fin_chg_code,	 		price_code,	 		dest_zone_code,
 		posting_code,			recurring_flag, 		recurring_code,
 		tax_code,	 		payment_code,	 		payment_type,	 
 		cust_po_num,			non_ar_flag,			gl_acct_code,	 
 		gl_trx_id,			prompt1_inp,			prompt2_inp,
 		prompt3_inp,			prompt4_inp,			deposit_num,
 		amt_gross,			
 		amt_freight,			amt_tax,
 		amt_discount,			amt_paid_to_date,	 	
 		amt_net,		 
 		amt_on_acct,			amt_cost,			
 		amt_tot_chg,		 
 		amt_discount_taken,		amt_write_off_given,		user_id,
 		void_flag,		 	paid_flag,	 		date_paid,
 		posted_flag,			commission_flag,		cash_acct_code,
 		non_ar_doc_num,		purge_flag,			db_action,
 		nat_cur_code,			rate_type_home,
 		rate_type_oper,		rate_home,			rate_oper,
		amt_tax_included,	org_id
 	)
 	SELECT	" ",				" ",				trx.doc_ctrl_num,
 		trx.trx_type,			trx.order_ctrl_num,		trx.doc_desc,
 		" ",	 			2071,	 	@today,
 		@today,			@date_applied,		@date_applied,		
 		0,				0,				trx.date_due,
 		trx.date_aging,		trx.customer_code,		trx.ship_to_code,
 		trx.salesperson_code,	trx.territory_code,		trx.comment_code,
 		trx.fob_code,			" ",	 	" ",
 		trx.fin_chg_code,	 	trx.price_code,	 	" ",
 		trx.posting_code,		0, 				" ",	
 		" ",	 			" ",	 			0,	 
 		" ",				0,				gl_acct_code,	 
 		" ",			" ",				" ",
 		" "	,			" ",				" ",
 		ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), gl.curr_precision), 			
 		0.0,				0.0,
 		0.0,				0.0,	 	
 		ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), gl.curr_precision), 	 
 		0.0,				0.0,			
 		ROUND(fin.late_chg_amt/( SIGN(1 + SIGN(trx.rate_home))*(trx.rate_home) + (SIGN(ABS(SIGN(ROUND(trx.rate_home,6))))/(trx.rate_home + SIGN(1 - ABS(SIGN(ROUND(trx.rate_home,6)))))) * SIGN(SIGN(trx.rate_home) - 1) ), gl.curr_precision), 		 
 		0.0,		 		0.0,	 			@user_id,
		0,				0,				0,
 		1,				0,				" ",
 		" ",				0,				2,
 		trx.nat_cur_code,		trx.rate_type_home,
 		trx.rate_type_oper,		trx.rate_home,		trx.rate_oper,
		0.0,					trx.org_id
 	FROM	#artrx_work trx, arfinchg fin, #cust_info cust, glcurr_vw gl
 	WHERE	trx.fin_chg_code = fin.fin_chg_code
 	AND	trx.customer_code = cust.customer_code
 	AND	cust.late_chg_type = 1 	
 	AND	trx.nat_cur_code = gl.currency_code
 	AND	trx.temp_flag = 0
	AND	trx.apply_to_num = trx.doc_ctrl_num 
	AND	trx.apply_trx_type = trx.trx_type
	AND	fin.late_chg_amt > 0.0
	AND	((trx.amt_tot_chg) > (trx.amt_paid_to_date) + 0.0000001)
	AND	trx.date_due < @date_applied

 	IF( @@error != 0 )
 	BEGIN
 		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 434, 5 ) + " -- EXIT: "
 		RETURN 34563
 	END
	
	
	DELETE	#artrx_work
	FROM	#prev_charges	prev
	WHERE	#artrx_work.trx_type = 2071
	AND	prev.trx_type = 2071
	AND	prev.apply_to_num = #artrx_work.apply_to_num
	AND	prev.apply_trx_type = #artrx_work.apply_trx_type
	AND	prev.date_applied >= @date_applied
 	
 	
	UPDATE	#artrx_work
	SET	doc_desc = typ.trx_type_desc
	FROM	artrxtyp typ
	WHERE	#artrx_work.trx_type = typ.trx_type
	AND	#artrx_work.trx_type = 2071

 	IF( @@error != 0 )
 	BEGIN
 		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 461, 5 ) + " -- EXIT: "
 		RETURN 34563
 	END
	
	IF ( @debug_level > 0 )
 	BEGIN
 		SELECT "dumping late charges in #artrx_work after ONCE PER INVOICE"
 		SELECT	"trx_type = " + STR(trx_type, 7) +
 			"customer_code = " + customer_code +
 			"apply_to_num = " + apply_to_num +
 			"rate_home = " + STR(rate_home, 10, 2) +
 			"amt_net = " + STR(amt_net, 10, 2)
 		FROM	#artrx_work
 		WHERE	trx_type = 2071
 	END
	
 	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflalte.sp", 477, "Leaving ARFLApplyLTEcharges_SP", @PERF_time_last OUTPUT
 	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflalte.sp" + ", line " + STR( 478, 5 ) + " -- EXIT: "
 	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLApplyLTEcharges_SP] TO [public]
GO
