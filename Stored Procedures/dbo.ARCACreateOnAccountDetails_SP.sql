SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 

















































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCACreateOnAccountDetails_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint = 0,
						@perf_level		smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcacoad.cpp", 52, "Entering ARCACreateOnAccountDetails_SP", @PERF_time_last OUTPUT




















BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacoad.cpp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "

	



	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,			rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
		org_id
	)
	SELECT	pyt.date_applied,			dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id),	
		pyt.trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			pyt.amt_on_acct,			
		pyt.nat_cur_code,			pyt.rate_type_home,			
		pyt.rate_type_oper,			pyt.rate_home,			
		pyt.rate_oper,			pyt.trx_type,				
		0,					pyt.trx_ctrl_num,
		pyt.org_id											
	FROM	#arinppyt_work pyt, arpymeth meth 
	WHERE	pyt.payment_code = meth.payment_code
	AND	pyt.batch_code = @batch_ctrl_num
	AND	pyt.non_ar_flag = 0
	AND	pyt.payment_type between 0 and 2
	AND	pyt.trx_type between 2113 and 2121
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacoad.cpp" + ", line " + STR( 107, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	



	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,			rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
		org_id
	)
	SELECT	pyt.date_applied, dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id), 	
		pyt.trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			-pdt.amt_applied,			
		pyt.nat_cur_code,			pyt.rate_type_home,			
		pyt.rate_type_oper,			pyt.rate_home,			
		pyt.rate_oper,			pyt.trx_type,				
		0,					pyt.trx_ctrl_num,
		pyt.org_id	
													
	FROM	#arinppdt_work pdt, #arinppyt_work pyt, arpymeth meth 
	WHERE	pdt.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pyt.payment_code = meth.payment_code
	AND	pyt.trx_type = 2112
	AND	pyt.payment_type between 0 and 2
	AND	pyt.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacoad.cpp" + ", line " + STR( 144, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	

IF (@debug_level > 0)
	BEGIN
		SELECT "dumping argldist after on acct details are added"
		SELECT	"date_applied journal_type rec_company_code account code description document_1 document_2"
		SELECT	STR(date_applied, 7) + ":" +
			journal_type + ":" +
			rec_company_code + ":" +
			account_code + ":" +
			description + ":" +
			document_1 + ":" +
			document_2
		FROM	#argldist
					
		SELECT	"document_2 reference_code home_balance home_cur_code nat_balance nat_cur_code rate trx_type seq_ref_id"
		SELECT	document_2 + ":" +
			reference_code + ":" +
			STR(home_balance, 10, 4) + ":" +
			home_cur_code + ":" +
			STR(nat_balance, 10, 4) + ":" +
			nat_cur_code + ":" +
			STR(rate_home, 10, 6) + ":" +
			STR(trx_type, 5 ) + ":" +
			STR(seq_ref_id, 6)
		FROM	#argldist
	END
END
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacoad.cpp" + ", line " + STR( 175, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcacoad.cpp", 176, "Leaving ARCACreateOnAcctDetails_SP", @PERF_time_last OUTPUT
	RETURN 0 

GO
GRANT EXECUTE ON  [dbo].[ARCACreateOnAccountDetails_SP] TO [public]
GO
