SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                

CREATE PROC [dbo].[ARWOMoveUnpostedRecords_SP]	@batch_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE	@result	int,
		@sys_date	int,
		@total_count	int,
		@cmax		int,
		@counter	int,
		@trx_num	varchar( 16 )




IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arwomur.cpp", 66, "Entering ARWOMoveUnpostedRecords_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwomur.cpp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "

	IF (@debug_level >= 2)
	BEGIN
		SELECT "Dumping #arinppdt_work..."
		SELECT	doc_ctrl_num + ' ' +
			trx_ctrl_num + ' ' +
			customer_code + ' ' +
			apply_to_num + ' ' +
			STR(amt_tot_chg)
		FROM	#arinppdt_work

	END

	



	EXEC appdate_sp @sys_date OUTPUT

	INSERT #artrxage_work 
	(
		trx_ctrl_num,			doc_ctrl_num, 		apply_to_num, 
		trx_type,		  	date_doc, 			date_due, 
		date_aging, 			customer_code, 		salesperson_code,
		territory_code, 		price_code, 			amount, 
		paid_flag, 			apply_trx_type,		ref_id, 
		group_id, 			sub_apply_num, 		sub_apply_type, 
		amt_fin_chg,			amt_late_chg, 		amt_paid, 
		date_applied, 		cust_po_num, 			order_ctrl_num,
		db_action,			rate_home,			rate_oper,
		nat_cur_code,			true_amount,			date_paid,
		payer_cust_code,		journal_ctrl_num,		account_code,
		org_id
	)      
	SELECT wo.trx_ctrl_num,		wo.doc_ctrl_num, 		inv.apply_to_num, 
		wo.trx_type,		  	@sys_date, 			inv.date_due, 
		inv.date_aging, 		wo.customer_code, 		inv.salesperson_code,
		inv.territory_code,		inv.price_code, 		- inv.amount , 
		1, 				inv.apply_trx_type,		0, 
		0, 				inv.sub_apply_num, 		inv.sub_apply_type, 
		0.0,				0.0,				0.0, 
		pyt.date_applied, 		' ',			 	' ',
		2,		inv.rate_home,		inv.rate_oper,
		inv.nat_cur_code,		- inv.amount ,			
										0,
		wo.customer_code,		' ',				' ',
		inv.org_id								
	FROM	#arinppyt_work pyt, #arinppdt_work wo, #artrxage_work inv
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.trx_ctrl_num = wo.trx_ctrl_num
	AND 	wo.apply_to_num = inv.apply_to_num
	AND	wo.apply_trx_type = inv.apply_trx_type
	AND	inv.trx_type in (2021, 2031, 2071)
	AND	inv.sub_apply_type = inv.trx_type
	AND	inv.sub_apply_num = inv.doc_ctrl_num


	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwomur.cpp" + ", line " + STR( 129, 5 ) + " -- EXIT: "
		DROP TABLE #artrxage_woffs
		RETURN 34563
	END

	


	UPDATE	#artrxage_work
	SET	journal_ctrl_num = tmp.journal_ctrl_num,
		account_code = dbo.IBAcctMask_fn(acct.ar_acct_code,trx.org_id)
	FROM	#artrx_work trx, #arwotemp tmp, araccts acct
	WHERE	#artrxage_work.trx_ctrl_num = tmp.trx_ctrl_num
	AND	#artrxage_work.sub_apply_num = trx.doc_ctrl_num
	AND	#artrxage_work.sub_apply_type = trx.trx_type
	AND	trx.posting_code = acct.posting_code

	IF (@debug_level > 2)
	BEGIN
		SELECT " Dumping #artrxage_work..."
		SELECT	" trx_ctrl_num = " + trx_ctrl_num +
			" doc_ctrl_num = " + doc_ctrl_num +
					" apply_to_num = " + apply_to_num +
			" sub_apply_num = " + sub_apply_num +
			" trx_type = " + STR(trx_type,6) +
			" customer_code = " + customer_code +
			" amount = " + STR(amount,10,2) +
			" ref_id = " + STR(ref_id, 10)
		FROM #artrxage_work

	END

	CREATE TABLE	#count_per_trx
	(
		ctrl_num	varchar(16),
		total_count	smallint,
		flag		int
	)

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwomur.cpp" + ", line " + STR( 170, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT INTO #count_per_trx
	SELECT	trx_ctrl_num, COUNT(trx_ctrl_num), 0
	FROM #artrxage_work
	GROUP BY trx_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwomur.cpp" + ", line " + STR( 181, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	SET rowcount 1

	WHILE EXISTS( select flag from #count_per_trx where flag = 0 )
	BEGIN	

		SELECT @counter = 1

		SELECT	@trx_num = ctrl_num,
			@cmax = total_count
		FROM	#count_per_trx
		WHERE	flag = 0

		UPDATE #count_per_trx
		SET	flag = 1
		WHERE	ctrl_num = @trx_num

		WHILE (@counter <= @cmax)
		BEGIN
			UPDATE #artrxage_work
			SET	ref_id = @counter
			WHERE	ref_id = 0
			AND	trx_ctrl_num = @trx_num
			AND	trx_type = 2151

			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwomur.cpp" + ", line " + STR( 211, 5 ) + " -- EXIT: "
				DROP TABLE #count_per_trx
				RETURN 34563
			END

			SELECT @counter = @counter + 1
		END

	END

	SET rowcount 0

	DROP TABLE #count_per_trx

	



	INSERT	#artrxpdt_work 
	(
		doc_ctrl_num,				trx_ctrl_num,		sequence_id,	
		gl_trx_id,  				customer_code,		trx_type,	
		apply_trx_type,				apply_to_num,		date_aging,	
		date_applied,				amt_applied,		amt_disc_taken,	
		amt_wr_off,					void_flag,	   		line_desc,	
		posted_flag,				sub_apply_type, 	sub_apply_num,	
		amt_tot_chg,				amt_paid_to_date,	terms_code,	
		posting_code,				db_action,			payer_cust_code,
		gain_home,					gain_oper,			inv_amt_applied,
		inv_amt_disc_taken,			inv_amt_wr_off,		inv_cur_code,
		org_id,						writeoff_code
	)
	SELECT	age.doc_ctrl_num, 		age.trx_ctrl_num,		age.ref_id,
   		tmp.journal_ctrl_num,		age.customer_code,		age.trx_type,
		age.apply_trx_type,			age.apply_to_num,		age.date_aging,
		age.date_applied,			0.0,					0.0,
		-age.amount,				0,						wo.line_desc,
		1,							age.sub_apply_type,		age.sub_apply_num,
		trx.amt_tot_chg,			0.0,					trx.terms_code,
		trx.posting_code,			2,						age.payer_cust_code,
		0.0,						0.0,					0.0,
		0.0,						-age.amount,			age.nat_cur_code,
		trx.org_id,					wo.writeoff_code								
	FROM	#artrxage_work age, #artrx_work trx, #arwotemp tmp, #arinppdt_work wo
	WHERE	age.apply_to_num = trx.doc_ctrl_num
	AND	age.apply_trx_type = trx.trx_type
	AND	age.trx_ctrl_num = tmp.trx_ctrl_num
	AND	age.trx_ctrl_num = wo.trx_ctrl_num
	AND age.ref_id = wo.sequence_id
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwomur.cpp" + ", line " + STR( 261, 5 ) + " -- EXIT: "
		RETURN 34563
	END	

	IF (@debug_level >= 2)
	BEGIN
		SELECT " Dumping #artrxpdt_work... "
		SELECT " trx_ctrl_num = " + trx_ctrl_num +
			" doc_ctrl_num = " + doc_ctrl_num +
			" sequence_id = " + STR(sequence_id,3) +
			" trx_type = " + STR(trx_type,6) +
			" customer_code = " + customer_code +
			" apply_to_num = " + apply_to_num +
			" sub_apply_num = " + sub_apply_num +
			" amt_applied = " + STR(amt_applied, 10,2) +
			" db_action = " + STR(db_action,2)
		FROM #artrxpdt_work
	END	

	


	UPDATE #arinppyt_work
	SET	db_action = db_action | 4
	WHERE	batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwomur.cpp" + ", line " + STR( 289, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE #arinppdt_work
	SET	db_action = #arinppdt_work.db_action | 4
	FROM	#arinppyt_work a
	WHERE	#arinppdt_work.trx_ctrl_num = a.trx_ctrl_num
	AND	#arinppdt_work.trx_type = a.trx_type
	AND	a.batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwomur.cpp" + ", line " + STR( 302, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arwomur.cpp", 306, "Leaving ARWOMoveUnpostedRecords_SP", @PERF_time_last OUTPUT

	RETURN 0 

END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARWOMoveUnpostedRecords_SP] TO [public]
GO
