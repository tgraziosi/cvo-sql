SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[APPYLockInsertDepend_sp]	
					 @process_group_num 	varchar(16),
					 @debug_level			smallint = 0
 
AS

DECLARE
	@result					int



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 120, 5 ) + " -- ENTRY: "

		BEGIN TRAN LOCKDEPS

		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 124, 5 ) + " -- MSG: " + "mark vouchers in apvohdr"
		UPDATE apvohdr
		SET state_flag = -1,
		    process_ctrl_num = @process_group_num
		FROM apvohdr a, #appypdt_work b
		WHERE a.trx_ctrl_num = b.apply_to_num
		AND a.state_flag = 1

		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 132, 5 ) + " -- MSG: " + "mark on-account payments in appyhdr"
		UPDATE appyhdr
		SET state_flag = -1,
		    process_ctrl_num = @process_group_num
		FROM appyhdr a, #appypyt_work b
		WHERE a.doc_ctrl_num = b.doc_ctrl_num
		AND a.cash_acct_code = b.cash_acct_code
		AND a.state_flag = 1
		AND a.void_flag = 0
		AND b.payment_type IN (2,3)
		AND a.payment_type IN (1,3)


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 145, 5 ) + " -- MSG: " + "insert vouchers that could not be marked in #ewerror"
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
							830,
							b.apply_to_num,
							"",
							0,
							0.0,
							1,
							b.trx_ctrl_num,
							b.sequence_id,
							"",
							0
		FROM apvohdr a, #appypdt_work b
		WHERE a.trx_ctrl_num = b.apply_to_num
		AND a.process_ctrl_num != @process_group_num

		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 173, 5 ) + " -- MSG: " + "insert on_acct payments that could not be marked in #ewerror"
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
							840,
							a.doc_ctrl_num,
							"",
							0,
							0.0,
							1,
							b.trx_ctrl_num,
							0,
							"",
							0
		FROM appyhdr a, #appypyt_work b
		WHERE a.doc_ctrl_num = b.doc_ctrl_num
		AND a.cash_acct_code = b.cash_acct_code
		AND a.process_ctrl_num != @process_group_num
		AND b.payment_type IN (2,3)
		AND a.payment_type IN (1,3)



		COMMIT TRAN LOCKDEPS


    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 209, 5 ) + " -- MSG: " + "Insert voucher header records into #appytrxv_work"
	INSERT #appytrxv_work
		(
		 trx_ctrl_num,
		 date_applied,
		 date_due,
		 date_paid,
		 posting_code,
	     vendor_code,
	     pay_to_code,	
		 branch_code,	
		 class_code,	
		 paid_flag,
	     amt_net,	  
	     amt_paid_to_date,	  
		 nat_cur_code,
		 rate_type_home,
		 rate_type_oper,
		 rate_home,
		 rate_oper,
		 db_action,
		 org_id	          
		)
	SELECT   DISTINCT
			 a.trx_ctrl_num,
			 a.date_applied,
			 a.date_due,
			 a.date_paid,
			 a.posting_code,
		     a.vendor_code,
		     a.pay_to_code,	
			 a.branch_code,	
			 a.class_code,	
			 a.paid_flag,
		     a.amt_net,	  
		     a.amt_paid_to_date,
			 a.currency_code,
			 a.rate_type_home,
			 a.rate_type_oper,
			 a.rate_home,
			 a.rate_oper,
			 0,
			 a.org_id		
	FROM apvohdr a, #appypdt_work b
	WHERE	a.process_ctrl_num = @process_group_num
	AND a.trx_ctrl_num = b.apply_to_num

	IF( @@error != 0 )
		RETURN -1



	



    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 265, 5 ) + " -- MSG: " + "Insert on-account payment header records into #appytrxp_work"
    INSERT	#appytrxp_work
	(	
	trx_ctrl_num,
	doc_ctrl_num,
	posting_code,
	cash_acct_code,
	branch_code,
	class_code,
    amt_on_acct,	   
	payment_type,  
	next_sequence_id,
	db_action  
	)					   
	SELECT DISTINCT
		a.trx_ctrl_num,
		a.doc_ctrl_num,
		"",
		a.cash_acct_code,
		"",
		"",
    	a.amt_on_acct,	   
		a.payment_type,  
		0,
		0
	FROM	appyhdr a, #appypyt_work b
	WHERE	a.process_ctrl_num = @process_group_num
	AND a.doc_ctrl_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code
	AND a.void_flag = 0
	AND b.payment_type IN (2,3)
	AND a.payment_type IN (1,3)

	IF( @@error != 0 )
		RETURN -1


	UPDATE #appytrxp_work
	SET next_sequence_id = (SELECT ISNULL(MAX(sequence_id),0) FROM appydet
							WHERE trx_ctrl_num = #appytrxp_work.trx_ctrl_num)

	UPDATE #appytrxp_work
	SET posting_code = b.posting_code,
		branch_code = b.branch_code,
		class_code = b.class_code
	FROM #appytrxp_work a, apdmhdr b
	WHERE a.doc_ctrl_num = b.trx_ctrl_num
	AND a.payment_type = 3


	


		
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 319, 5 ) + " -- MSG: " + "Insert voucher aging records into #appyagev_work"
    INSERT	#appyagev_work
	(	
		trx_ctrl_num,
		date_aging,
		amount,
		paid_flag,
		date_paid,
		db_action		
	)
	SELECT
		a.trx_ctrl_num,
		a.date_aging,
		a.amount,
		a.paid_flag,
		a.date_paid,
		0
	FROM	aptrxage a, #appytrxv_work b
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num
	AND		a.trx_type = 4091



	IF( @@error != 0 )
		RETURN -1


	


		
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 350, 5 ) + " -- MSG: " + "Insert on account aging records into #appyageo_work"
    INSERT	#appyageo_work
	(	
		trx_type,
		doc_ctrl_num,
		cash_acct_code,
		paid_flag,
		date_paid,
		db_action		
	)
	SELECT
		a.trx_type,
		a.doc_ctrl_num,
	 	a.cash_acct_code,
		a.paid_flag,
		a.date_paid,
		0
	FROM	aptrxage a, #appytrxp_work b
	WHERE	a.doc_ctrl_num = b.doc_ctrl_num
	AND     a.cash_acct_code = b.cash_acct_code
	AND		a.trx_type IN (4111,4161)
	AND     a.apply_trx_type = 0


	IF( @@error != 0 )
		RETURN -1




	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appylid.cpp" + ", line " + STR( 380, 5 ) + " -- EXIT: "			 
	RETURN 0

GO
GRANT EXECUTE ON  [dbo].[APPYLockInsertDepend_sp] TO [public]
GO
