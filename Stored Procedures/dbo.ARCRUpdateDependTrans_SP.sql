SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 






















































































































































































































































































































































































































































































































 


















































































CREATE PROC [dbo].[ARCRUpdateDependTrans_SP]	@batch_ctrl_num	varchar(16),
						@process_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@date_applied		int,
	@curr_precision		smallint  



IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrudt.cpp", 79, "Entering ARCRUpdateDependTrans", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 82, 5 ) + " -- ENTRY: "
		
	
 
	
	SELECT @curr_precision = curr_precision
        FROM glco, glcurr_vw
        WHERE glco.home_currency = glcurr_vw.currency_code
	
	IF ( @debug_level >= 2 )
	BEGIN
		SELECT "dumping #artrxage_work..db_action=20..."
		SELECT "apply_to_num = " + apply_to_num +
			"apply_trx_type = " + STR(apply_trx_type, 6 ) +
			"sub_apply_num = " + sub_apply_num +
			"sub_apply_type = " + STR(sub_apply_type, 6 ) +
			"date_aging = " + STR(date_aging, 8 ) +
			"trx_type = " + STR(trx_type, 6) +
			"amount = " + STR(amount, 10, 2 ) 
		FROM	#artrxage_work
		WHERE	db_action = 20	 
	END
	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arcrudt.cpp", 122, "Start Updating ARTRXAGE Dependant records", @PERF_time_last OUTPUT	
	CREATE TABLE #arage_pymt
	(
		apply_to_num		varchar(16),
		apply_trx_type	int,
		sub_apply_num		varchar(16),
		sub_apply_type	int,
		date_aging		int,
		amt_paid_delta	float,
		amt_discount		float
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 135, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	INSERT	#arage_pymt (	
				apply_to_num,
				apply_trx_type,
				sub_apply_num,
				sub_apply_type,
				date_aging,
				amt_paid_delta,
				amt_discount
			 )
	SELECT	apply_to_num,
		apply_trx_type,
		sub_apply_num,
		sub_apply_type,
		date_aging,
		-SUM(amount),
		-SUM( amount * (1 - ABS(SIGN(trx_type - 2131)) ) )
	FROM	#artrxage_work
	WHERE	db_action = 20 
	AND	trx_type in (2032,2111,2131,2141)
	AND	ref_id != -1
	GROUP BY apply_to_num, apply_trx_type, sub_apply_num, sub_apply_type, date_aging

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 171, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF ( @debug_level >= 2 )
	BEGIN
		SELECT "dumping #arage_pymt..."
		SELECT "apply_to_num = " + apply_to_num +
			"apply_trx_type = " + STR(apply_trx_type, 6 ) +
			"sub_apply_num = " + sub_apply_num +
			"sub_apply_type = " + STR(sub_apply_type, 6 ) +
			"date_aging = " + STR(date_aging, 8 ) +
			"amt_paid_delta = " + STR(amt_paid_delta, 10, 2 ) +
			"amt_discount = " + STR(amt_discount, 10, 2 ) 
		FROM	#arage_pymt		 
	END
	

	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN

		/* Begin mod: CB0001 - Update the chargeback records with the journal control number */
		UPDATE	#artrx_work
		SET	gl_trx_id = gl.journal_ctrl_num
		FROM	#artrx_work a, #arcrtemp gl
		WHERE	a.prompt1_inp = gl.trx_ctrl_num
		AND	(a.doc_ctrl_num LIKE 'CB%'
		OR	 a.doc_ctrl_num LIKE 'CA%')
	
		UPDATE	#artrxage_work
		SET	journal_ctrl_num = a.gl_trx_id
		FROM	#artrxage_work, #artrx_work a, #arcrtemp gl
		WHERE	#artrxage_work.trx_ctrl_num = a.trx_ctrl_num
		AND	a.prompt1_inp = gl.trx_ctrl_num
		AND	(a.doc_ctrl_num LIKE 'CB%'
		OR	 a.doc_ctrl_num LIKE 'CA%')
	
		/* Begin Fix: Call 1819 */
		/* Begin Fix: Call 1997 
		UPDATE	#artrxage_work
		SET	account_code = ''
		WHERE	(doc_ctrl_num LIKE 'CB%'
		OR	 doc_ctrl_num LIKE 'CA%')
		AND	journal_ctrl_num = ''
		** End Fix: Call 1997 */
		/* End Fix: Call 1819 */
	
		/* End mod: CB0001 */

		/* Begin mod: CB0002 - Update credit memo aging records with the journal control number */
		UPDATE	#artrxage_work
		SET	journal_ctrl_num = gl.journal_ctrl_num
		FROM	#arcrtemp gl
		WHERE	#artrxage_work.trx_ctrl_num = gl.trx_ctrl_num
		AND	#artrxage_work.apply_trx_type = 2161
		AND	#artrxage_work.trx_type = 2111
		/*  End mod:  CB0002 */
	END
	
	UPDATE	#artrxage_work
	SET	db_action = 2,
		journal_ctrl_num = gl.journal_ctrl_num
	FROM	#arcrtemp gl
	WHERE	#artrxage_work.trx_ctrl_num = gl.trx_ctrl_num
	AND	db_action = 20
	
	
	UPDATE	#artrxage_work
	SET	amt_paid = amt_paid + amt_paid_delta,
		db_action = db_action | 1
	FROM	#arage_pymt pymt
	WHERE	pymt.sub_apply_num = #artrxage_work.doc_ctrl_num
	AND	pymt.sub_apply_type = #artrxage_work.trx_type
	AND	pymt.date_aging = #artrxage_work.date_aging
	AND	#artrxage_work.trx_type IN (2021, 2031, 2071)	
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 215, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	SELECT @date_applied = 0
	
	SET ROWCOUNT 1
	SELECT @date_applied	= date_applied
	FROM	#arinppyt_work
	WHERE	batch_code = @batch_ctrl_num
	SET ROWCOUNT 0
	
	
	
	IF( @debug_level >= 2 )
	BEGIN
		SELECT "Dumping #artrxage_work after updating dependant transactions"
		SELECT	"doc_ctrl_num = " + doc_ctrl_num +
			" trx_type = " + STR(trx_type,6) +
			" payer_cust_code = " + payer_cust_code +
			" customer_code = " + customer_code +
		 	" amount = " + STR(amount,10,2) +
		 	" paid_flag = " + STR(paid_flag,2) +
		 	" amt_paid = " + STR(amt_paid, 10,2) +
		 	" db_action = " + STR(db_action, 2)
		FROM #artrxage_work
	END

	

	
	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arcrudt.cpp", 260, "Start Updating ARTRX Dependant records", @PERF_time_last OUTPUT	

	
	CREATE TABLE #mast_inv_amts
	(
		apply_to_num		varchar(16),
		apply_trx_type	int,
		total			float,
		amt_discount		float
	)

	INSERT	#mast_inv_amts
		( apply_to_num, apply_trx_type, total, amt_discount )
	SELECT	apply_to_num, apply_trx_type, sum(amt_paid_delta), sum(amt_discount)
	FROM	#arage_pymt pymt
	GROUP BY apply_to_num, apply_trx_type
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 281, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF (@debug_level >= 2)
	BEGIN
		SELECT "dumping #mast_inv_amts...."
		SELECT	"apply_to_num = " + apply_to_num +
			"apply_trx_type = " + STR(apply_trx_type, 8 ) +
			"total = " + STR(total, 10, 2 ) +
			"amt_discount = " + STR(amt_discount, 10, 2 )
		FROM	#mast_inv_amts
	END

	
	CREATE TABLE #inv_amts
	(
		sub_apply_num		varchar(16),
		sub_apply_type	int,
		total			float
	)
	
	INSERT	#inv_amts
	SELECT	sub_apply_num, sub_apply_type, SUM(amt_paid_delta)
	FROM	#arage_pymt pymt
	GROUP BY sub_apply_num, sub_apply_type

	DROP TABLE #arage_pymt
	
	
	UPDATE #artrx_work
	SET	amt_paid_to_date = amt_paid_to_date + inv.total,
		amt_discount_taken = ISNULL(amt_discount_taken, 0.0) + inv.amt_discount,
		db_action = db_action | 1
	FROM	#mast_inv_amts inv
	WHERE	inv.apply_to_num = #artrx_work.doc_ctrl_num
	AND	inv.apply_trx_type = #artrx_work.trx_type
		
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 325, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	UPDATE #artrx_work
	SET	amt_paid_to_date = inv.total,
		db_action = db_action | 1
	FROM	#inv_amts inv
	WHERE	inv.sub_apply_num = #artrx_work.doc_ctrl_num
	AND	inv.sub_apply_type = #artrx_work.trx_type
	AND	#artrx_work.apply_to_num != #artrx_work.doc_ctrl_num
		
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 339, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	DROP TABLE #inv_amts
	
	UPDATE	#artrx_work
	SET	paid_flag = SIGN(1 - SIGN(ROUND(amt_tot_chg - amt_paid_to_date,6))),
		date_paid = SIGN(1 + SIGN(date_paid - @date_applied - 0.5)) * date_paid +
				SIGN(1 + SIGN(@date_applied - date_paid)) * @date_applied				
	FROM	#mast_inv_amts inv
	WHERE	inv.apply_to_num = #artrx_work.doc_ctrl_num
	AND	inv.apply_trx_type = #artrx_work.trx_type

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 358, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	DROP TABLE #mast_inv_amts
	
	
	
	
	CREATE TABLE #from_onacct
	 ( 	payer_cust_code	varchar(8),
		doc_ctrl_num		varchar(16),
		tot_amt_applied	float	)
			
	
	INSERT	#from_onacct ( payer_cust_code, doc_ctrl_num, tot_amt_applied )
	SELECT	payer_cust_code, doc_ctrl_num, ISNULL( SUM(amt_applied), 0.0 )
	FROM	#arinppdt_work
	WHERE	temp_flag = 1
	GROUP BY payer_cust_code, doc_ctrl_num
	
	IF (@debug_level >= 2 )
	BEGIN
		SELECT "Dumping #from_onacct..."
		SELECT	"payer_cust_code = " + payer_cust_code +
			"doc_ctrl_num = " + doc_ctrl_num +
			"tot_amt_applied = " + STR(tot_amt_applied, 10, 2)
		FROM	#from_onacct
	END

	UPDATE	#artrx_work
	SET	amt_on_acct = ROUND(amt_on_acct, @curr_precision) - ROUND(onacct.tot_amt_applied, @curr_precision),
		db_action = db_action | 1
	FROM	#from_onacct onacct
	WHERE	onacct.payer_cust_code = #artrx_work.customer_code
	AND	onacct.doc_ctrl_num = #artrx_work.doc_ctrl_num
	AND	trx_type = 2111



	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN

		/* Begin Mod: FIX1730 - Add trx_ctrl_num to #from_onacct. */

		UPDATE	#artrx_work
		SET	amt_on_acct = round(#artrx_work.amt_on_acct + isnull(cb.total_chargebacks,0),@curr_precision),
			db_action = #artrx_work.db_action | 1
		FROM	#arinppyt_work py, arcbtot cb
		WHERE	py.customer_code = #artrx_work.customer_code
		AND	py.doc_ctrl_num = #artrx_work.doc_ctrl_num
		AND	#artrx_work.trx_type = 2111
		AND	py.trx_ctrl_num = cb.trx_ctrl_num

		/* End Mod: FIX1730 */
	END
	
	DROP TABLE #from_onacct	
	
	
	UPDATE	#artrx_work
	SET	paid_flag = 1 - SIGN(amt_on_acct),
		date_paid = SIGN(1 + SIGN(date_paid - @date_applied - 0.5)) * date_paid +
				SIGN(1 + SIGN(@date_applied - date_paid)) * @date_applied,
		db_action = db_action | 1
	WHERE	trx_type = 2111
	
	
	UPDATE	#artrxage_work
	SET	paid_flag = trx.paid_flag,
		date_paid = trx.date_paid,
		db_action = age.db_action | 1
	FROM	#artrxage_work age, #artrx_work trx
	WHERE	age.customer_code = trx.customer_code
	AND	age.doc_ctrl_num = trx.doc_ctrl_num
	AND	age.ref_id = 0
	AND	trx.payment_type in (1, 3)
	
	IF( @debug_level >= 2 )
	BEGIN
		SELECT "Dumping artrx_work records after updating dependant transactions"
		SELECT	"doc_ctrl_num = " + doc_ctrl_num +
			" trx_type = " + STR(trx_type,6) +
			" customer_code = " + customer_code +
			" amt_net = " + STR(amt_net,10,2) +
			" void_flag = " + STR(void_flag,2) +
			" amt_on_acct = " + STR(amt_on_acct, 10,2) +
			" amt_paid_to_date = " + STR(amt_paid_to_date, 10,2) +
			" amt_discount_taken = " + STR(amt_discount_taken, 10, 2)+
			" paid_flag = " + STR(paid_flag, 2) +
			" date_paid = " + STR(date_paid, 10) +
			" db_action = " + STR(db_action,2)
		FROM #artrx_work
	END
	
	
	UPDATE	#artrxage_work
	SET	paid_flag = SIGN(1 - SIGN(ABS(ROUND(amt_tot_chg - amt_paid_to_date,6)))),
		date_paid = trx.date_paid,
		db_action = #artrxage_work.db_action | 1
	FROM	#artrx_work trx
	WHERE	#artrxage_work.apply_to_num = trx.doc_ctrl_num
	AND	#artrxage_work.apply_trx_type = trx.trx_type
	AND	#artrxage_work.trx_type IN (2021, 2031, 2071)	

	IF( @debug_level >= 2 )
	BEGIN
		SELECT "Dumping artrxage_work records after updating dependant transactions"
		SELECT	"doc_ctrl_num = " + doc_ctrl_num +
			" trx_type = " + STR(trx_type,6) +
			" customer_code = " + customer_code +
			" paid_flag = " + STR(paid_flag, 2) +
			" date_paid = " + STR(date_paid, 10) +
			" db_action = " + STR(db_action,2)
		FROM #artrxage_work
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrudt.cpp" + ", line " + STR( 479, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrudt.cpp", 480, "Leaving ARCRUpdateDependantTrans_SP", @PERF_time_last OUTPUT
    RETURN 0 

END   

GO
GRANT EXECUTE ON  [dbo].[ARCRUpdateDependTrans_SP] TO [public]
GO
