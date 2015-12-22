SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 


































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCACreateTaxDetails_SP]		@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
    	@result             	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcactd.cpp", 58, "Entering ARCACreateTaxDetails_SP", @PERF_time_last OUTPUT







BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcactd.cpp" + ", line " + STR( 67, 5 ) + " -- ENTRY: "
	


	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,				rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num
	)
	SELECT	DISTINCT 
		pyt.date_applied,			tax.sales_tax_acct_code,
		pyt.trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			taxwork.amt_final_tax,
		pyt.nat_cur_code,			pyt.rate_type_home,
		pyt.rate_type_oper,			pyt.rate_home,
		pyt.rate_oper,				pyt.trx_type,
		0,					pyt.trx_ctrl_num
	FROM	#arinppyt_work pyt, #arnonardet_work pdt, #arinptax_work taxwork, artxtype tax
	WHERE	pyt.batch_code        = @batch_ctrl_num
	AND	pyt.trx_ctrl_num      = pdt.trx_ctrl_num
	AND	pyt.trx_ctrl_num      = taxwork.trx_ctrl_num
	AND	pyt.trx_type          = taxwork.trx_type
	AND	taxwork.tax_type_code = tax.tax_type_code
	AND	pyt.non_ar_flag       = 1

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcactd.cpp" + ", line " + STR( 99, 5 ) + " -- EXIT: "
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
	FROM	#arinppyt_work chg, #arinptax_work cdt, artax tax, arnonardet d, artaxdet e
	WHERE	chg.batch_code        	= @batch_ctrl_num
	AND	chg.trx_ctrl_num      	= cdt.trx_ctrl_num
	and	cdt.tax_type_code     	= e.tax_type_code
	and     d.trx_ctrl_num        	= cdt.trx_ctrl_num
	and     d.tax_code            	= tax.tax_code
	and	e.tax_code		= tax.tax_code
	AND	tax.tax_included_flag 	= 1 
	GROUP BY chg.trx_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcactd.cpp" + ", line " + STR( 131, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	CREATE TABLE #pyt_tax_sums
	(
		trx_ctrl_num	varchar(16),
		amt_tax_included	float
	)
	INSERT	#pyt_tax_sums
	SELECT	chg.trx_ctrl_num,
		SUM(d.amt_tax)
	FROM	#arinppyt_work chg, #arinptax_work cdt, artax tax, arnonardet d, artaxdet e
	WHERE	chg.batch_code        = @batch_ctrl_num
	AND	chg.trx_ctrl_num      = cdt.trx_ctrl_num
	and	cdt.tax_type_code     = e.tax_type_code
	and     d.trx_ctrl_num        = cdt.trx_ctrl_num
	and     d.tax_code            = tax.tax_code
	and	e.tax_code	      = tax.tax_code
	AND	tax.tax_included_flag = 1 
	GROUP BY chg.trx_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcactd.cpp" + ", line " + STR( 155, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	


	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,				rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num	
	)
	SELECT	DISTINCT
		chg.date_applied,			dbo.IBAcctMask_fn(acct.tax_rounding_acct_code,chg.org_id),	
		chg.trx_desc,				chg.customer_code,
		chg.doc_ctrl_num,			cdt.amt_tax_included - pyt.amt_tax_included,
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,				chg.trx_type,				
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
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcactd.cpp" + ", line " + STR( 191, 5 ) + " -- EXIT: "
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

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcactd.cpp" + ", line " + STR( 218, 5 ) + " -- EXIT: "
END

GO
GRANT EXECUTE ON  [dbo].[ARCACreateTaxDetails_SP] TO [public]
GO
