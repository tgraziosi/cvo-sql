SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










CREATE PROC [dbo].[APPALockInsertDepend_sp]
					 @process_group_num 	varchar(16),
					 @debug_level			smallint = 0
 
AS

DECLARE
	@result					int


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appalid.cpp" + ", line " + STR( 128, 5 ) + " -- ENTRY: "

		BEGIN TRAN LOCKDEPS

		UPDATE apvohdr
		SET state_flag = -1,
		    process_ctrl_num = @process_group_num
		FROM apvohdr a, #appapdt_work b
		WHERE a.trx_ctrl_num = b.apply_to_num
		AND a.state_flag = 1
	
		IF( @@error != 0 )
		  BEGIN
		    ROLLBACK TRAN
			RETURN -1
		  END


		UPDATE appyhdr
		SET state_flag = -1,
		    process_ctrl_num = @process_group_num
		FROM appyhdr a, #appapyt_work b
		WHERE a.doc_ctrl_num = b.doc_ctrl_num
		AND a.cash_acct_code = b.cash_acct_code
		AND a.payment_type IN (1,3)
		AND a.state_flag = 1

		IF( @@error != 0 )
		  BEGIN
		    ROLLBACK TRAN
			RETURN -1
		  END


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appalid.cpp" + ", line " + STR( 162, 5 ) + " -- MSG: " + "insert vouchers that could not be marked in #ewerror"
		INSERT #ewerror(    module_id,
							err_code,
							info1,
							info2,
							infoint,
							infofloat,
							flag1,
							trx_ctrl_num,
							sequence_id,
							source_ctrl_num,
							extra
						)
		SELECT				4000,
							40830,
							b.apply_to_num,
							"",
							0,
							0.0,
							1,
							b.trx_ctrl_num,
							b.sequence_id,
							"",
							0
		FROM apvohdr a, #appapdt_work b
		WHERE a.trx_ctrl_num = b.apply_to_num
		AND a.process_ctrl_num != @process_group_num

		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appalid.cpp" + ", line " + STR( 190, 5 ) + " -- MSG: " + "insert on_acct payments that could not be marked in #ewerror"
		INSERT #ewerror(    module_id,
							err_code,
							info1,
							info2,
							infoint,
							infofloat,
							flag1,
							trx_ctrl_num,
							sequence_id,
							source_ctrl_num,
							extra
						)
		SELECT				4000,
							40840,
							a.doc_ctrl_num,
							"",
							0,
							0.0,
							1,
							b.trx_ctrl_num,
							0,
							"",
							0
		FROM appyhdr a, #appapyt_work b
		WHERE a.doc_ctrl_num = b.doc_ctrl_num
		AND a.cash_acct_code = b.cash_acct_code
		AND a.payment_type IN (1,3)
		AND a.process_ctrl_num != @process_group_num



		COMMIT TRAN LOCKDEPS


	



	INSERT	#appatrxp_work
	(	
		trx_ctrl_num,	
		trx_type,	
		doc_ctrl_num,	
		date_doc,	
		date_applied,
		year,
		posting_code,	
		vendor_code,	
		pay_to_code,
		branch_code,
		class_code,	
		cash_acct_code,	
		void_flag,	
		amt_payment,
		amt_discount,	
		amt_on_acct,	
		payment_type,	
		db_action		   	
	)					   
	SELECT DISTINCT
		a.trx_ctrl_num,	
		4111,	
		a.doc_ctrl_num,	
		a.date_doc,	
		a.date_applied,
		0,
		"",	
		a.vendor_code,	
		a.pay_to_code,
		c.branch_code,
		c.vend_class_code,	
		a.cash_acct_code,	
		a.void_flag,	
		a.amt_net,
		a.amt_discount,	
		a.amt_on_acct,	
		a.payment_type,	
		0
	FROM	appyhdr a, #appapyt_work b, apvend c
	WHERE	process_ctrl_num = @process_group_num
	AND	 a.doc_ctrl_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code
	AND a.vendor_code = c.vendor_code
	AND a.payment_type IN (1,3)

	IF( @@error != 0 )
		RETURN -1


	UPDATE #appatrxp_work
	SET posting_code = b.posting_code,
		branch_code = b.branch_code,
		class_code = b.class_code
	FROM #appatrxp_work a, apdmhdr b
	WHERE a.doc_ctrl_num = b.trx_ctrl_num
	AND a.payment_type = 3

	IF( @@error != 0 )
		RETURN -1

	INSERT	#appatrxv_work
	(	
	trx_ctrl_num,
	date_paid,
	vendor_code,
	pay_to_code,
	posting_code,
	branch_code,	
	class_code,	
	paid_flag,
    amt_net,	  
    amt_paid_to_date,	  
	old_paid_flag,
    rate_type_home,
    rate_type_oper,
    rate_home,
    rate_oper,  
	db_action,
	org_id		
	)					   
	SELECT DISTINCT
		a.trx_ctrl_num,	
		a.date_paid,	
		a.vendor_code,
		a.pay_to_code,
		a.posting_code,	
		a.branch_code,	
		a.class_code,	
		a.paid_flag,	
		a.amt_net,	
		a.amt_paid_to_date,	
		a.paid_flag,
	    a.rate_type_home,
	    a.rate_type_oper,
	    a.rate_home,
	    a.rate_oper,  
		0,
	    a.org_id 
	FROM	apvohdr a, #appapdt_work b
	WHERE	process_ctrl_num = @process_group_num
	AND     a.trx_ctrl_num = b.apply_to_num

	IF( @@error != 0 )
		RETURN -1

	INSERT #appadsb_work
		(
		check_ctrl_num,
		onacct_ctrl_num,
		trx_ctrl_num,
		doc_ctrl_num,
		sequence_id,
		apply_to_num,
		check_num,
		cash_acct_code,
		db_action
		)
	SELECT DISTINCT
		a.check_ctrl_num,
		a.onacct_ctrl_num,
		a.trx_ctrl_num,
		a.doc_ctrl_num,
		a.sequence_id,
		a.apply_to_num,
		a.check_num,
		a.cash_acct_code,
		0
    FROM apchkdsb a, #appatrxp_work b
	WHERE a.check_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code




	INSERT #appappdt_work (
		trx_ctrl_num,
		sequence_id,
		void_flag,
		date_apply_doc,
		date_aging,
		db_action )
	SELECT 
		a.trx_ctrl_num,
		a.sequence_id,
		a.void_flag,
		a.date_applied,
		a.date_aging,
		0
	FROM	appydet a, #appatrxp_work b
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num

	IF( @@error != 0 )
		RETURN -1
 


	


		
	INSERT	#appaxage_work
	(	
		trx_ctrl_num,
		trx_type,
		doc_ctrl_num,
		ref_id,
		apply_to_num,
		apply_trx_type,
		date_doc,
		date_applied,
		date_due,
		date_aging,
		vendor_code,
		pay_to_code,
		class_code,
		branch_code,
		amount,
		amt_paid_to_date,
		cash_acct_code,
		paid_flag,
		date_paid,
		nat_cur_code,
		rate_home,
		rate_oper,
		journal_ctrl_num,
		account_code,
		org_id,
		db_action		
	)
	SELECT
		a.trx_ctrl_num,
		a.trx_type,
		a.doc_ctrl_num,
		a.ref_id,
		a.apply_to_num,
		a.apply_trx_type,
		a.date_doc,
		a.date_applied,
		a.date_due,
		a.date_aging,
		a.vendor_code,
		a.pay_to_code,
		a.class_code,
		a.branch_code,
		a.amount,
		a.amt_paid_to_date,
		a.cash_acct_code,
		a.paid_flag,
		a.date_paid,
		a.nat_cur_code,
		a.rate_home,
		a.rate_oper,
		a.journal_ctrl_num,
		a.account_code,
		a.org_id,
		0
	FROM	aptrxage a, #appatrxp_work b
	WHERE	a.doc_ctrl_num = b.doc_ctrl_num
	AND		a.cash_acct_code = b.cash_acct_code
	AND		a.trx_type IN (4111,4011,4161,4131,4171)


	IF( @@error != 0 )
		RETURN -1


	


		
	INSERT	#appaxage_work
	(	
		trx_ctrl_num,
		trx_type,
		doc_ctrl_num,
		ref_id,
		apply_to_num,
		apply_trx_type,
		date_doc,
		date_applied,
		date_due,
		date_aging,
		vendor_code,
		pay_to_code,
		class_code,
		branch_code,
		amount,
		amt_paid_to_date,
		cash_acct_code,
		paid_flag,
		date_paid,
		nat_cur_code,
		rate_home,
		rate_oper,
		journal_ctrl_num,
		account_code,
		org_id,
		db_action		
	)
	SELECT
		a.trx_ctrl_num,
		a.trx_type,
		a.doc_ctrl_num,
		a.ref_id,
		a.apply_to_num,
		a.apply_trx_type,
		a.date_doc,
		a.date_applied,
		a.date_due,
		a.date_aging,
		a.vendor_code,
		a.pay_to_code,
		a.class_code,
		a.branch_code,
		a.amount,
		a.amt_paid_to_date,
		a.cash_acct_code,
		a.paid_flag,
		a.date_paid,
		a.nat_cur_code,
		a.rate_home,
		a.rate_oper,
		a.journal_ctrl_num,
		a.account_code,
		a.org_id,
		0
	FROM	aptrxage a, #appatrxv_work b
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num
	AND		a.trx_type = 4091


	IF( @@error != 0 )
		RETURN -1




	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appalid.cpp" + ", line " + STR( 528, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[APPALockInsertDepend_sp] TO [public]
GO
