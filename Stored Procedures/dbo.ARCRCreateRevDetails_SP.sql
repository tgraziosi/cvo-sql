SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 


































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRCreateRevDetails_SP]		@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
    	@result             	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcrd.cpp", 68, "Entering ARCRCreateRevDetails_SP", @PERF_time_last OUTPUT











BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcrd.cpp" + ", line " + STR( 81, 5 ) + " -- ENTRY: "
	



	


	





























	


	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,		nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,		rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
		reference_code,                         org_id        
                	
	)

	SELECT	
		pyt.date_applied,			pdt.gl_acct_code,
		pyt.trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			-(pdt.extended_price),
		pyt.nat_cur_code,			pyt.rate_type_home,
		pyt.rate_type_oper,	pyt.rate_home,
		pyt.rate_oper,				pyt.trx_type,
		0,			pyt.trx_ctrl_num,
		pdt.reference_code,                     pdt.org_id        
	FROM	#arinppyt_work pyt, #arnonardet_work pdt
	WHERE	batch_code            = @batch_ctrl_num
	AND	pyt.trx_ctrl_num      = pdt.trx_ctrl_num
	AND	pyt.non_ar_flag       = 1
 	AND    ABS(pdt.extended_price-pdt.amt_tax) > 0 







	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcrd.cpp" + ", line " + STR( 158, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	



	IF (@debug_level > 0)
		BEGIN
			SELECT "dumping argldist after Revenue details are added"
			SELECT	"date_applied journal_type rec_company_code account code description document_1 document_2"
			SELECT	STR(date_applied, 7) + ":" +
					account_code + ":" +
					description + ":" +
					document_1 + ":" +
					document_2
			FROM	#argldist
					
			SELECT	"document_2 reference_code nat_balance nat_cur_code rate trx_type"
			SELECT	document_2 + ":" +
				reference_code + ":" +
					STR(nat_balance, 10, 4) + ":" +
					nat_cur_code + ":" +
					STR(trx_type, 5 ) 
			FROM	#argldist
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcrd.cpp" + ", line " + STR( 186, 5 ) + " -- EXIT: "
END

GO
GRANT EXECUTE ON  [dbo].[ARCRCreateRevDetails_SP] TO [public]
GO
