SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 

















































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCAcreateOACMdetails_SP]	@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcaoacm.cpp", 45, "Entering ARCAcreateOACMdetails_SP", @PERF_time_last OUTPUT












BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaoacm.cpp" + ", line " + STR( 59, 5 ) + " -- ENTRY: "

	



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
	SELECT	pyt.date_applied,			dbo.IBAcctMask_fn(acct.cm_on_acct_code,pyt.org_id),	
		pyt.trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			-pdt.amt_applied,			
		pyt.nat_cur_code,			pyt.rate_type_home,			
		pyt.rate_type_oper,			pyt.rate_home,			
		pyt.rate_oper,				pyt.trx_type,				
		0,					pyt.trx_ctrl_num,
		pyt.org_id
	FROM	#arinppdt_work pdt, #arinppyt_work pyt, #artrx_work trx, araccts acct 
	WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pyt.customer_code = trx.customer_code
	AND	pyt.doc_ctrl_num = trx.doc_ctrl_num
	AND	trx.posting_code = acct.posting_code
	AND	pyt.batch_code = @batch_ctrl_num
	AND	pyt.trx_type = 2112
	AND	trx.trx_type = 2111
	AND	pyt.non_ar_flag = 0
	AND	pyt.payment_type = 3

	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaoacm.cpp" + ", line " + STR( 99, 5 ) + " -- EXIT: "
		RETURN 34563
	END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcaoacm.cpp" + ", line " + STR( 103, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcaoacm.cpp", 104, "Leaving ARCAcreateOACMdetails_SP", @PERF_time_last OUTPUT
RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARCAcreateOACMdetails_SP] TO [public]
GO
