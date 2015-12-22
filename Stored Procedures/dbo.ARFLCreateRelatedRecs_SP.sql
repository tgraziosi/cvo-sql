SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 






















































































































































































































































































































































































































































































































 

















































































CREATE PROC [dbo].[ARFLCreateRelatedRecs_SP]	@batch_ctrl_num	varchar(16),
						@user_id		smallint,
						@charge_option	smallint,
						@debug_level		smallint,
						@perf_level		smallint

AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result	int,
	@today		int


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflcrr.sp", 65, "Entering ARFLCreateHeaderRecs", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflcrr.sp" + ", line " + STR( 68, 5 ) + " -- ENTRY: "
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping #artrxage_work..."
		SELECT	"doc_ctrl_num = " + doc_ctrl_num +
			"apply_to_num = " + apply_to_num +
			"amount = " + STR(amount, 10, 2) 
		FROM	#artrxage_work
		WHERE	trx_type = 2061
		
		SELECT	"dumping #artrx_work..."
		SELECT	"doc_ctrl_num = " + doc_ctrl_num +
			"apply_to_num = " + apply_to_num +
			"amt_net = " + STR(amt_net, 10, 2)
		FROM	#artrx_work
		WHERE	trx_type = 2071
	END
	
	
	EXEC appdate_sp @today OUTPUT

	IF ( SIGN(@charge_option) != 0 )
	BEGIN
		
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
			amt_gross,			amt_freight,			amt_tax,
			amt_discount,			amt_paid_to_date,	 	amt_net,		 
			amt_on_acct,			amt_cost,			amt_tot_chg,		 
			amt_discount_taken,		amt_write_off_given,		user_id,
			void_flag,		 	paid_flag,	 		date_paid,
			posted_flag,			commission_flag,		cash_acct_code,
			non_ar_doc_num,		purge_flag,			db_action,
			process_group_num,		temp_flag,			source_trx_ctrl_num,
			source_trx_type,		nat_cur_code,			rate_type_home,
			rate_type_oper,		rate_home,			rate_oper,
			amt_tax_included,	org_id
		)
		SELECT	age.doc_ctrl_num,	 	age.trx_ctrl_num,		age.sub_apply_num,
			age.sub_apply_type, 		age.order_ctrl_num, 	typ.trx_type_desc,
			" ", 			age.trx_type,	 		@today,
			@today,			age.date_applied,		age.date_doc,		
			0,				0,				age.date_due,
			age.date_aging,		age.customer_code,		" ",
			age.salesperson_code,	age.territory_code,		" ",
			" ",				" ",	 			" ",
			" ",	 			age.price_code,	 	" ",
			" ",				0, 				" ",
			" ",	 			" ",	 			0,	 
			age.cust_po_num,		0,				" ",	 
			" ",				" ",				" ",
			" ",				" ",				" ",
			age.amount,			0.0,				0.0,
			0.0,				0.0,	 			age.amount,		 
			0.0,				0.0,				age.amount,		 
			0.0,				0.0,				@user_id,
			0,				0,				0,
			1,				0,				" ",
			" ",				0,				2,
			NULL,				0,				NULL,
			NULL,				age.nat_cur_code,		" ",
			" ",				age.rate_home,		age.rate_oper,
			0.0,				age.org_id
		FROM	#artrxage_work age, artrxtyp typ
		WHERE	age.trx_type = typ.trx_type
		AND	age.trx_type = 2061

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflcrr.sp" + ", line " + STR( 160, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		
		SELECT inv.ship_to_code, 
			inv.posting_code, 
			inv.rate_type_home, 
			inv.rate_type_oper,
			inv.fin_chg_code,
			inv.doc_ctrl_num,
			inv.trx_type,
			chg.trx_type chg_trx_type
		INTO	#inv_info
		FROM	#artrx_work chg, #artrx_work inv
		WHERE	chg.apply_to_num = inv.doc_ctrl_num
		AND	chg.apply_trx_type = inv.trx_type
		AND	chg.trx_type = 2061
 
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflcrr.sp" + ", line " + STR( 183, 5 ) + " -- EXIT: "
			RETURN 34563
		END
			

		UPDATE	#artrx_work
		SET	ship_to_code = inv.ship_to_code,
			posting_code = inv.posting_code,
			rate_type_home = inv.rate_type_home,
			rate_type_oper = inv.rate_type_oper,
			fin_chg_code = inv.fin_chg_code
		FROM	#inv_info inv
		WHERE	#artrx_work.apply_to_num = inv.doc_ctrl_num
		AND	#artrx_work.apply_trx_type = inv.trx_type
		AND	#artrx_work.trx_type = inv.chg_trx_type
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflcrr.sp" + ", line " + STR( 201, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		DROP TABLE #inv_info
	END 

	
	IF ( SIGN(@charge_option - 1) != 0 )
	BEGIN
		INSERT	#artrxage_work 
		(	trx_ctrl_num, 		trx_type, ref_id, 
			doc_ctrl_num, order_ctrl_num, 	cust_po_num,
			apply_to_num, 		apply_trx_type, 	sub_apply_num, 
			sub_apply_type, 	date_doc, date_due, 
			date_applied, 	date_aging, 	customer_code, 
			payer_cust_code,		salesperson_code,		territory_code, 		
			price_code,			amount,			
			paid_flag,		 	group_id,			amt_fin_chg,			
			amt_late_chg,			amt_paid,		 	db_action,			
			rate_home, 			rate_oper,			nat_cur_code,			
			true_amount,			date_paid,			journal_ctrl_num,		 	
			account_code,			org_id
		)
		SELECT	trx_ctrl_num, 		2071,		1,
			doc_ctrl_num,			" ",				" ",
			apply_to_num,	 		apply_trx_type, 		apply_to_num,
			apply_trx_type, 		date_applied,			date_due,
			date_applied,			date_aging,			customer_code,
			customer_code,		salesperson_code, 		territory_code,		
			price_code,			amt_net,		
			0,				0,				0.0,
			0.0,				0.0,				2,
			rate_home,			rate_oper,			nat_cur_code,
			amt_net,			0,				' ',
			' ',				org_id
		FROM	#artrx_work
		WHERE	trx_type = 2071
		
		
		CREATE TABLE #split_late
		(	doc_ctrl_num	varchar(16),
			sub_apply_num	varchar(16),
			sub_apply_type smallint,
			date_aging	int,
			date_due	int
		)
		
		INSERT	#split_late
		SELECT	age.doc_ctrl_num, age.sub_apply_num, age.sub_apply_type, 0,0
		FROM	#artrxage_work age
		WHERE	age.date_aging = 0
		AND	age.trx_type = 2071

		UPDATE #split_late
		SET	date_aging = inv.date_aging,
			date_due = inv.date_due		
		FROM	#artrxage_work inv
		WHERE	#split_late.sub_apply_num = inv.doc_ctrl_num
		AND	#split_late.sub_apply_type = inv.trx_type
		AND	inv.ref_id = 1
		
		UPDATE	#artrxage_work
		SET	date_aging = spl.date_aging,
			date_due = spl.date_due
		FROM	#split_late spl
		WHERE	#artrxage_work.doc_ctrl_num = spl.doc_ctrl_num
		AND	#artrxage_work.trx_type = 2071
		
		DROP TABLE #split_late
				
	END 
	
	IF (@debug_level >= 2)
	BEGIN
		SELECT "Dumping #artrx_work records after creating header records"
		SELECT	"doc_ctrl_num = " + doc_ctrl_num +
			" trx_type = " + STR(trx_type,6) +
			" customer_code = " + customer_code +
			" amt_net = " + STR(amt_net,10,2) +
			" paid_flag = " + STR(paid_flag,2) +
			" db_action = " + STR(db_action, 2)
		FROM #artrx_work
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflcrr.sp" + ", line " + STR( 291, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflcrr.sp", 292, "Leaving ARFLCreateRelatedRecs_SP", @PERF_time_last OUTPUT
 	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARFLCreateRelatedRecs_SP] TO [public]
GO
