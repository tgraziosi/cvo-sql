SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 






















































































































































































































































































































































































































































































































 


































































































CREATE PROC [dbo].[ARFLUpdateDependTrans_SP]	@batch_ctrl_num	varchar(16),
						@process_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@process_group_num	varchar(16),
	@x_user_id		smallint,
	@x_sys_date		int, 
	@batch_type		smallint,
	@period_end 		int 



IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arfludt.sp", 70, "Entering ARFLUpdateDependTrans", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfludt.sp" + ", line " + STR( 73, 5 ) + " -- ENTRY: "
	
	
		
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_group_num OUTPUT,
					@x_user_id OUTPUT,
					@x_sys_date OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfludt.sp" + ", line " + STR( 93, 5 ) + " -- EXIT: "
		RETURN 35011
	END
	
	
	SELECT	trx_type, sub_apply_num, sub_apply_type, date_aging, date_applied, amount
	INTO	#age_fin_late
	FROM	#artrxage_work
	WHERE	trx_type IN (2061, 2071)
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfludt.sp" + ", line " + STR( 111, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#artrxage_work
	SET	amt_fin_chg = inv.amt_fin_chg + chg.amount,
		db_action = inv.db_action | 1
	FROM	#artrxage_work inv, #age_fin_late chg 
	WHERE	chg.sub_apply_num = inv.doc_ctrl_num
	AND	chg.sub_apply_type = inv.trx_type
	AND	chg.date_aging = inv.date_aging
	AND	chg.trx_type = 2061
	AND	inv.trx_type >= 2021
	AND	inv.trx_type <= 2031
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfludt.sp" + ", line " + STR( 128, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#artrxage_work
	SET	amt_late_chg = inv.amt_late_chg + chg.amount,
		db_action = inv.db_action | 1
	FROM	#artrxage_work inv, #age_fin_late chg
 	WHERE	chg.sub_apply_num = inv.doc_ctrl_num
	AND	chg.sub_apply_type = inv.trx_type
	AND	chg.trx_type = 2071
	AND	inv.trx_type >= 2021
	AND	inv.trx_type <= 2031
	AND	inv.ref_id = 1

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfludt.sp" + ", line " + STR( 149, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#artrxage_work
	SET	date_paid = SIGN(1 + SIGN(date_paid - chg.date_applied - 0.5)) * date_paid +
				SIGN(1 + SIGN(chg.date_applied - date_paid)) * chg.date_applied,
		db_action = inv.db_action | 1
	FROM	#artrxage_work inv, #age_fin_late chg
 	WHERE	chg.sub_apply_num = inv.doc_ctrl_num
	AND	chg.sub_apply_type = inv.trx_type
	AND	chg.trx_type >= 2061
	AND	chg.trx_type <= 2071
	AND	inv.trx_type >= 2021
	AND	inv.trx_type <= 2031

	DROP TABLE #age_fin_late
	
	
	
	CREATE TABLE #fl_sum
	( apply_to_num	varchar(16),
	 apply_trx_type	smallint,
	 mast_apply_num	varchar(16),
	 mast_apply_type	smallint,
	 date_applied	int,	 
	 amount		float
	)
	
	
	INSERT #fl_sum
	(
		apply_to_num, 		apply_trx_type,
		mast_apply_num,		mast_apply_type,
		date_applied,			amount
	)
	SELECT	inv.doc_ctrl_num,		inv.trx_type,
		inv.apply_to_num,		inv.apply_trx_type,
		MIN(fl.date_applied),	SUM(fl.amt_net)
	FROM	#artrx_work fl, #artrx_work inv
	WHERE	fl.trx_type >= 2061
	AND	fl.trx_type <= 2071
	AND	fl.apply_to_num = inv.doc_ctrl_num
	AND	fl.apply_trx_type = inv.trx_type
	AND	inv.trx_type >= 2021
	AND	inv.trx_type <= 2031
	GROUP BY inv.doc_ctrl_num, inv.trx_type, inv.apply_to_num, inv.apply_trx_type
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping #fl_sum..."
		SELECT "apply_to_num = " + apply_to_num +
			"apply_trx_type = " + STR(apply_trx_type, 5)+
			"mast_apply_num = " + mast_apply_num +
			"mast_apply_type = " + STR(mast_apply_type, 5)+
			"date_applied = " + STR(date_applied, 8) +
			"amount = " + STR(amount, 10, 2 )
		FROM	#fl_sum
	END

	
	SELECT	mast_apply_num, mast_apply_type, MIN(date_applied) date_applied, SUM(amount) amount
	INTO	#mast_sum
	FROM	#fl_sum
	GROUP BY mast_apply_num, mast_apply_type
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping #mast_sum..."
		SELECT "mast_apply_num = " + mast_apply_num +
			"mast_apply_type = " + STR(mast_apply_type, 5)+
			"date_applied = " + STR(date_applied, 8) +
			"amount = " + STR(amount, 10, 2 )
		FROM	#mast_sum
	END
	
	
	UPDATE	#artrx_work
	SET	amt_tot_chg = amt_tot_chg + #mast_sum.amount,
		date_paid = SIGN(1 + SIGN(#artrx_work.date_paid - #mast_sum.date_applied - 0.5)) * #artrx_work.date_paid +
				SIGN(1 + SIGN(#mast_sum.date_applied - #artrx_work.date_paid)) * #mast_sum.date_applied,
		db_action = #artrx_work.db_action | 1 
	FROM	#mast_sum
	WHERE	#mast_sum.mast_apply_num = #artrx_work.doc_ctrl_num
	AND	#mast_sum.mast_apply_type = #artrx_work.trx_type
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping #artrx_work..."
		SELECT "doc_ctrl_num = " + doc_ctrl_num +
			"trx_type = " + STR(trx_type, 5)+
			"amt_tot_chg = " + STR(amt_tot_chg, 10, 2)
		FROM	#artrx_work
	END
	
	DROP TABLE #mast_sum
	
	DELETE	#fl_sum
	WHERE	apply_to_num = mast_apply_num
	AND	apply_trx_type = mast_apply_type
	
	
	UPDATE	#artrx_work
	SET	amt_tot_chg = amt_tot_chg + amount,
		db_action = db_action | 1
	FROM	#fl_sum fl
	WHERE	fl.apply_to_num = #artrx_work.doc_ctrl_num
	AND	fl.apply_trx_type = #artrx_work.trx_type
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfludt.sp" + ", line " + STR( 277, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	DROP TABLE #fl_sum
	
	IF( @debug_level >= 2 )
	BEGIN
		SELECT "Dumping artrx_work records after updating dependant transactions"
		SELECT	"doc_ctrl_num = " + doc_ctrl_num +
			" trx_type = " + STR(trx_type,6) +
			" customer_code = " + customer_code +
			" amt_net = " + STR(amt_net,10,2) +
			" amt_tot_chg = " + STR(amt_tot_chg, 10,2) +
			" paid_flag = " + STR(paid_flag, 2) +
			" db_action = " + STR(db_action,2)
		FROM #artrx_work
	END
	
	IF( @debug_level >= 2 )
	BEGIN
		SELECT "Dumping #artrxage_work after updating dependant transactions"
		SELECT	"doc_ctrl_num = " + doc_ctrl_num +
			" trx_type = " + STR(trx_type,6) +
			" customer_code = " + customer_code +
		 	" amount = " + STR(amount,10,2) +
		 	" amt_fin_chg = " + STR(amt_fin_chg,10,2) +
		 	" amt_late_chg = " + STR(amt_late_chg,10,2) +
		 	" db_action = " + STR(db_action, 2)
		FROM #artrxage_work
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arfludt.sp" + ", line " + STR( 309, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arfludt.sp", 310, "Leaving ARFLUpdateDependantTrans_SP", @PERF_time_last OUTPUT
	
 RETURN 0 

END 

GO
GRANT EXECUTE ON  [dbo].[ARFLUpdateDependTrans_SP] TO [public]
GO
