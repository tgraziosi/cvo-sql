SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 











































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRcreateOACMdetails_SP]	@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result		int,
	@journal_type		varchar(8),
	@company_code		varchar(8),
	@home_currency	varchar(8),
	@oper_currency	varchar(8),
	@reference_code	varchar(8)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcroacm.cpp", 68, "Entering ARCRcreateOACMdetails_SP", @PERF_time_last OUTPUT












BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcroacm.cpp" + ", line " + STR( 82, 5 ) + " -- ENTRY: "


	SELECT	@journal_type = journal_type
	FROM	glappid
	WHERE	app_id = 2000
	
	IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcroacm.cpp" + ", line " + STR( 91, 5 ) + " -- EXIT: "
			RETURN 34563
		END

	SELECT	@company_code = company_code,
		@home_currency = home_currency,
		@oper_currency = oper_currency
	FROM	glco
	
	IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcroacm.cpp" + ", line " + STR( 102, 5 ) + " -- EXIT: "
			RETURN 34563
		END

	SELECT	@reference_code = " "
	
	IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcroacm.cpp" + ", line " + STR( 110, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
	CREATE TABLE #amt_applied
	(	trx_ctrl_num	varchar(16),
		trx_type	smallint,
		amt_applied	float
	)
	
	INSERT #amt_applied
	SELECT	arinppdt.trx_ctrl_num, arinppdt.trx_type, SUM(arinppdt.amt_applied)
	FROM	#arinppyt_work arinppyt, #arinppdt_work arinppdt
	WHERE	arinppyt.batch_code = @batch_ctrl_num
	AND	arinppyt.trx_ctrl_num = arinppdt.trx_ctrl_num
	AND	arinppyt.trx_type = arinppdt.trx_type
	GROUP BY arinppdt.trx_ctrl_num, arinppdt.trx_type

	





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
		pyt.date_applied,			dbo.IBAcctMask_fn(acct.cm_on_acct_code,pyt.org_id), 
		trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			pdt.amt_applied,
		artrx.nat_cur_code,	  		artrx.rate_type_home,
		artrx.rate_type_oper,		artrx.rate_home,
		artrx.rate_oper,			pyt.trx_type,
		0,					pyt.trx_ctrl_num,
                pyt.org_id        
	FROM	#arinppyt_work pyt, araccts acct, #artrx_work artrx, #amt_applied pdt 
	WHERE	pyt.batch_code = @batch_ctrl_num
	AND	pyt.payment_type in (3, 4) 

	AND	pyt.non_ar_flag = 0
	AND	pyt.customer_code = artrx.customer_code
	AND	pyt.doc_ctrl_num = artrx.doc_ctrl_num
	AND	artrx.payment_type = 3
	AND	artrx.trx_type = 2111
	AND	artrx.posting_code = acct.posting_code
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	
	

 
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcroacm.cpp" + ", line " + STR( 173, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF (@debug_level > 0)
		BEGIN
		      	SELECT "dumping argldist after OACM details are added"
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcroacm.cpp" + ", line " + STR( 197, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcroacm.cpp", 198, "Leaving ARCRcreateOACMdetails_SP", @PERF_time_last OUTPUT
RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARCRcreateOACMdetails_SP] TO [public]
GO
