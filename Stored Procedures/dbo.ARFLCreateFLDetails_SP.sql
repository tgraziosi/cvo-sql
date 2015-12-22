SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 





























































































































































































































































































































                       







































































































































































































































































































































































CREATE PROC [dbo].[ARFLCreateFLDetails_SP]		@batch_ctrl_num	varchar(16),
						@debug_level		smallint = 0,
                                		@perf_level		smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									






	    
DECLARE
	@result		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arflcfld.cpp", 48, "Entering ARFLCreateFLDetails_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflcfld.cpp" + ", line " + STR( 51, 5 ) + " -- ENTRY: "

	

 
	INSERT	#argldist
	(
		date_applied,				
		account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,			rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
		org_id	
	)
	SELECT	trx.date_applied,			dbo.IBAcctMask_fn(pc.fin_chg_acct_code,trx.org_id),
		trx.doc_desc,				trx.customer_code,
		trx.doc_ctrl_num,			-trx.amt_net,				
		trx.nat_cur_code,			trx.rate_type_home,			
		trx.rate_type_oper,			trx.rate_home,			
		trx.rate_oper,			trx.trx_type,				
		0,					trx.trx_ctrl_num,
		trx.org_id
	FROM	araccts pc, #artrx_work trx
	WHERE	pc.posting_code = trx.posting_code
	AND	trx.trx_type = 2061
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflcfld.cpp" + ", line " + STR( 82, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	INSERT	#argldist
	(
		date_applied,				
		account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,			rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
		org_id	
	)
	SELECT	trx.date_applied,			dbo.IBAcctMask_fn(pc.late_chg_acct_code,trx.org_id),	
		trx.doc_desc,				trx.customer_code,
		trx.doc_ctrl_num,			-trx.amt_net,				
		trx.nat_cur_code,			trx.rate_type_home,			
		trx.rate_type_oper,			trx.rate_home,			
		trx.rate_oper,			trx.trx_type,				
		0,					trx.trx_ctrl_num,
		trx.org_id
	FROM	araccts pc, #artrx_work trx
	WHERE	pc.posting_code = trx.posting_code
	AND	trx.trx_type = 2071
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflcfld.cpp" + ", line " + STR( 112, 5 ) + " -- EXIT: "
		RETURN 34563
	END


		IF( @debug_level >= 2 )
	BEGIN
		SELECT	"dumping #arglidst..."
		SELECT	"date_applied journal_type rec_company_code account code description document_1 document_2"
		SELECT	STR(date_applied, 7) + ":" +
				journal_type + ":" +
				rec_company_code + ":" +
				account_code + ":" +
				description + ":" +
				document_1 + ":" +
				document_2
		FROM	#argldist
				
		SELECT	"document_2 home_balance home_cur_code nat_balance nat_cur_code rate trx_type seq_ref_id"
		SELECT	document_2 + ":" +
				STR(home_balance, 10, 4) + ":" +
				home_cur_code + ":" +
				STR(nat_balance, 10, 4) + ":" +
				nat_cur_code + ":" +
				STR(rate_home, 10, 6) + ":" +
				STR(rate_oper, 10, 6) + ":" +
				STR(trx_type, 5 ) + ":" +
				STR(seq_ref_id, 6)
		FROM	#argldist
	END
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arflcfld.cpp", 142, "Leaving ARFLCreateFLDetails_SP", @PERF_time_last OUTPUT
	RETURN 0 

END
GO
GRANT EXECUTE ON  [dbo].[ARFLCreateFLDetails_SP] TO [public]
GO
