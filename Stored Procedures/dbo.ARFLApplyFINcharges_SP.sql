SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLApplyFINcharges_SP]	@batch_ctrl_num	varchar( 16 ),
					@date_applied		int,
					@home_currency	varchar( 8 ),
					@oper_currency	varchar( 8 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0	
AS


DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()



DECLARE
 	@result	int


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflafin.sp", 62, "Entering ARFLApplyFinCharges_SP", @PERF_time_last OUTPUT
	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 64, 5 ) + " -- MSG: " + "Applying fin charges..."
	
	INSERT	#artrxage_work 
	(	trx_ctrl_num,		 	trx_type,			ref_id,
		doc_ctrl_num,			order_ctrl_num, 		cust_po_num,
		apply_to_num,			apply_trx_type,		sub_apply_num,
		sub_apply_type,		date_doc,			date_due,			
		date_applied,			date_aging,			customer_code,		
		payer_cust_code,		salesperson_code,		territory_code, 		
		price_code,			amount,			paid_flag,		 	
		group_id,			amt_fin_chg,			amt_late_chg,			
		amt_paid,		 	db_action,			rate_home, 			
		rate_oper,			nat_cur_code,			true_amount,		 	
		date_paid,			journal_ctrl_num,		account_code,
		org_id 
	)
	SELECT	" ",				2061,		age.ref_id,
		" ",				" ",				" ",
		age.apply_to_num,		age.apply_trx_type,		age.sub_apply_num,
		age.sub_apply_type,		@date_applied,		age.date_due,			
		@date_applied,		age.date_aging,		age.customer_code,		
		trx.fin_chg_code,		age.salesperson_code,	age.territory_code,		
		age.price_code,		age.amount,		 	0,				
		@date_applied-age.date_due,	age.amt_fin_chg,		0.0,				
		age.amt_paid,			2,		age.rate_home,		
		age.rate_oper,		age.nat_cur_code,		0.0,				
	 	0,				' ',				' ',
		age.org_id
	FROM	#artrx_work trx, #artrxage_work age, arfinchg fin, glcurr_vw gl
	WHERE	trx.trx_ctrl_num = age.trx_ctrl_num
	AND	trx.trx_type = age.trx_type
	AND	trx.fin_chg_code = fin.fin_chg_code
	AND	age.date_due < @date_applied
	AND	((amount+amt_fin_chg*fin.compound_chg_flag) > (amt_paid) + 0.0000001)
	AND	trx.nat_cur_code = gl.currency_code
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 108, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#artrxage_work
	SET	group_id = @date_applied - prev.date_applied
	FROM	#prev_charges prev, #artrxage_work age
	WHERE prev.sub_apply_num = age.sub_apply_num
	AND	prev.sub_apply_type = age.sub_apply_type
	AND	prev.date_aging = age.date_aging
	AND	prev.date_applied > age.date_due
	AND	age.trx_type = 2061
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 127, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	DELETE	#artrxage_work
	WHERE	trx_type = 2061
	AND	((group_id) <= (0) + 0.0000001)
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 142, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping #artrxage_work - finance chg"
		SELECT	"trx_type = " + STR(trx_type, 7) +
			"customer_code = " + customer_code +
			"sub_apply_num = " + sub_apply_num +
			"fin_chg_code = " + payer_cust_code +
			"rate_home = " + STR(rate_home, 10, 2) +
			"amount = " + STR(amount, 10, 2) +
			"group_id = " + STR(group_id, 7)
		FROM	#artrxage_work
		WHERE	trx_type = 2061
	END
		
	
	UPDATE	#artrxage_work
	SET	amount = 	
		 ROUND((amount - amt_paid + amt_fin_chg*chg.compound_chg_flag)
		 			
		 * CONVERT(float, chg.fin_chg_prc)/100.0 			
				
		 * CONVERT(float, group_id)/365, 
		 gl.curr_precision),
		amt_paid = ROUND(chg.min_fin_chg/( SIGN(1 + SIGN(fin.rate_home))*(fin.rate_home) + (SIGN(ABS(SIGN(ROUND(fin.rate_home,6))))/(fin.rate_home + SIGN(1 - ABS(SIGN(ROUND(fin.rate_home,6)))))) * SIGN(SIGN(fin.rate_home) - 1) ), gl.curr_precision)
	FROM	arfinchg chg, glcurr_vw gl, #artrxage_work fin
	WHERE	fin.payer_cust_code = chg.fin_chg_code 
	AND	fin.nat_cur_code = gl.currency_code
	AND	fin.trx_type = 2061
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 184, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping #artrxage_work after amount update"
		SELECT	"trx_type = " + STR(trx_type, 7) +
			"customer_code = " + customer_code +
			"sub_apply_num = " + sub_apply_num +
			"min_fin_chg = " + STR(amt_paid, 10, 2) +
			"amount = " + STR(amount, 10, 2)
		FROM	#artrxage_work
		WHERE	trx_type = 2061
	END
	
	
	UPDATE	#artrxage_work
	SET	amount = amt_paid
	WHERE	#artrxage_work.amount < #artrxage_work.amt_paid
	AND	trx_type = 2061
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 212, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#artrxage_work
	SET	true_amount = amount,
		amt_fin_chg = 0.0,
		amt_paid = 0.0,
		payer_cust_code = customer_code
	WHERE	trx_type = 2061
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 229, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	DELETE	#artrxage_work
	WHERE	((amount) <= (0.0) + 0.0000001)
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 241, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflafin.sp", 245, "Leaving ARFLApplyFINcharges_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflafin.sp" + ", line " + STR( 246, 5 ) + " -- EXIT: "
	RETURN 0
END	
GO
GRANT EXECUTE ON  [dbo].[ARFLApplyFINcharges_SP] TO [public]
GO
