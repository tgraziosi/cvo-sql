SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 


































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRCreateTaxDetails_SP]		@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
    	@result             	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrctd.cpp", 62, "Entering ARCRCreateTaxDetails_SP", @PERF_time_last OUTPUT







BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrctd.cpp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "
	


	


	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,		nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,		rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num
	)
	SELECT	 
		pyt.date_applied,			dbo.IBAcctMask_fn(typ.sales_tax_acct_code, pyt.org_id),
		pyt.trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,	-tax.amt_final_tax,
		pyt.nat_cur_code,			pyt.rate_type_home,
		pyt.rate_type_oper,	pyt.rate_home,
		pyt.rate_oper,				pyt.trx_type,
		0,					pyt.trx_ctrl_num
	FROM	#arinppyt_work pyt, #arinptax_work tax, artxtype typ
	WHERE	pyt.batch_code        	= @batch_ctrl_num
	AND	pyt.trx_ctrl_num 	= tax.trx_ctrl_num
	AND	pyt.trx_type 		= tax.trx_type
	AND	tax.tax_type_code 	= typ.tax_type_code
	AND	pyt.non_ar_flag       = 1











	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrctd.cpp" + ", line " + STR( 115, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	






	


	CREATE TABLE #cdt_tax_sums
	(
		trx_ctrl_num	varchar(16),
		amt_tax_included	float
	)

	INSERT	#cdt_tax_sums
	SELECT	chg.trx_ctrl_num,
		SUM(cdt.amt_final_tax)
	FROM	#arinppyt_work chg, #arinptax_work cdt, artxtype typ
	WHERE	chg.batch_code        	= @batch_ctrl_num
	AND	chg.trx_ctrl_num 	= cdt.trx_ctrl_num
	AND	chg.trx_type 		= cdt.trx_type
	AND	cdt.tax_type_code 	= typ.tax_type_code
	AND	chg.non_ar_flag       = 1
	GROUP BY chg.trx_ctrl_num 


	


	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrctd.cpp" + ", line " + STR( 152, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	CREATE TABLE #pyt_tax_sums
	(
		trx_ctrl_num	varchar(16),
		amt_tax_included	float
	)

	INSERT	#pyt_tax_sums
	SELECT	chg.trx_ctrl_num,		SUM(d.amt_tax)
	FROM	arinppyt chg, arnonardet d
	WHERE	chg.batch_code        = @batch_ctrl_num
	AND	chg.trx_ctrl_num 	= d.trx_ctrl_num
	GROUP BY chg.trx_ctrl_num
	


	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrctd.cpp" + ", line " + STR( 173, 5 ) + " -- EXIT: "
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
		seq_ref_id,				trx_ctrl_num	
	)
	SELECT
		chg.date_applied,			dbo.IBAcctMask_fn(acct.tax_rounding_acct_code,chg.org_id),	
		chg.trx_desc,				chg.customer_code,
		chg.doc_ctrl_num,		cdt.amt_tax_included - pyt.amt_tax_included,
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,			chg.trx_type,				
		0,					chg.trx_ctrl_num
	FROM	#arinppyt_work chg, #cdt_tax_sums cdt, glcurr_vw gl, araccts acct, #pyt_tax_sums pyt, arcust arc
	WHERE	chg.trx_ctrl_num  = cdt.trx_ctrl_num
	AND     chg.trx_ctrl_num  = pyt.trx_ctrl_num
	AND	chg.nat_cur_code  = gl.currency_code
	AND	chg.customer_code = arc.customer_code
	AND	arc.posting_code  = acct.posting_code
	AND	ABS(ROUND(cdt.amt_tax_included - pyt.amt_tax_included, gl.curr_precision)) >= gl.rounding_factor	

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrctd.cpp" + ", line " + STR( 210, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #cdt_tax_sums
	DROP TABLE #pyt_tax_sums

	IF (@debug_level > 0)
		BEGIN
			SELECT "dumping argldist after Tax details are added"
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

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrctd.cpp" + ", line " + STR( 237, 5 ) + " -- EXIT: "
END

GO
GRANT EXECUTE ON  [dbo].[ARCRCreateTaxDetails_SP] TO [public]
GO
