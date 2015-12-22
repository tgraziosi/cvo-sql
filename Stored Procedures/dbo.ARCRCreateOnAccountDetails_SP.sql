SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 











































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRCreateOnAccountDetails_SP]	@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
    	@result             	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcoad.cpp", 64, "Entering ARCRCreateOnAccountDetails_SP", @PERF_time_last OUTPUT










BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcoad.cpp" + ", line " + STR( 76, 5 ) + " -- ENTRY: "
	
	


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
	SELECT
		date_applied,			      	dbo.IBAcctMask_fn(meth.on_acct_code,org_id), 
		trx_desc,				customer_code,
		doc_ctrl_num,				amt_on_acct*(-1),
		arinppyt.nat_cur_code,		rate_type_home,
		rate_type_oper,			rate_home,
		rate_oper,				trx_type,
		0,					trx_ctrl_num,
                arinppyt.org_id        
	FROM	#arinppyt_work arinppyt, arpymeth meth
	WHERE	arinppyt.batch_code = @batch_ctrl_num
	AND	arinppyt.payment_type = 1
	AND	arinppyt.payment_code = meth.payment_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcoad.cpp" + ", line " + STR( 107, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	CREATE TABLE #from_onacct
	(	trx_ctrl_num	varchar(16),
		amt_applied	float
	)
	
	INSERT #from_onacct
	SELECT	arinppyt.trx_ctrl_num, ISNULL(SUM(arinppdt.amt_applied), 0.0 )
	FROM	#arinppyt_work arinppyt, #arinppdt_work arinppdt
	WHERE	arinppyt.batch_code = @batch_ctrl_num
	AND	arinppyt.trx_ctrl_num = arinppdt.trx_ctrl_num
	AND	arinppyt.trx_type = arinppdt.trx_type
	AND	arinppyt.payment_type = 2
	GROUP BY arinppyt.trx_ctrl_num
		
	


	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,			        rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
                org_id        
	)
	SELECT
		date_applied,			      	dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id), 
		trx_desc,				customer_code,
		doc_ctrl_num,				pdt.amt_applied,
		pyt.nat_cur_code,		      	rate_type_home,
		rate_type_oper,			        rate_home,
		rate_oper,				trx_type,
		0,					pyt.trx_ctrl_num,
                pyt.org_id
	FROM	#arinppyt_work pyt, arpymeth meth, #from_onacct pdt
	WHERE	pyt.payment_code = meth.payment_code
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcoad.cpp" + ", line " + STR( 154, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	DROP TABLE #from_onacct

   	IF (@debug_level > 0)
		BEGIN
		      	SELECT "dumping argldist after on acct details are added"
			SELECT	"date_applied journal_type rec_company_code account code description document_1 document_2"
			SELECT	STR(date_applied, 7) + ":" +
					account_code + ":" +
					description + ":" +
					document_1 + ":" +
					document_2
			FROM	#argldist
					
			SELECT	"document_2 reference_code home_balance home_cur_code nat_balance nat_cur_code rate trx_type seq_ref_id"
			SELECT	document_2 + ":" +
					STR(nat_balance, 10, 4) + ":" +
					nat_cur_code + ":" +
					STR(trx_type, 5 ) + ":" +
					STR(seq_ref_id, 6)
			FROM	#argldist
	END
END
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcoad.cpp" + ", line " + STR( 180, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcoad.cpp", 181, "Leaving ARCRCreateOnAcctDetails_SP", @PERF_time_last OUTPUT
    	RETURN 0 

GO
GRANT EXECUTE ON  [dbo].[ARCRCreateOnAccountDetails_SP] TO [public]
GO
