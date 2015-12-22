SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCreateTaxDetails_SP]	@batch_ctrl_num     varchar( 16 ),
						@debug_level        smallint = 0,
						@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmctd.cpp", 73, "Entering ARCMCreateTaxDetails_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmctd.cpp" + ", line " + STR( 76, 5 ) + " -- ENTRY: "

	




	INSERT	#argldist
	(
		date_applied,			account_code,				
                description,
		document_1,			document_2,				nat_balance,
		nat_cur_code,			rate_home,				trx_type,
		seq_ref_id,			trx_ctrl_num,				rate_type_home,
		rate_type_oper,		        rate_oper,                              org_id        
	)
	SELECT	arinpchg.date_applied,	dbo.IBAcctMask_fn(artxtype.sales_tax_acct_code, arinpchg.org_id), 	
                arinpchg.doc_desc,
		arinpchg.customer_code,	arinpchg.doc_ctrl_num,		arinptax.amt_final_tax,
		nat_cur_code,			rate_home,				arinpchg.trx_type,
		0,				arinpchg.trx_ctrl_num,		rate_type_home,
		rate_type_oper,		        rate_oper,                      arinpchg.org_id                
	FROM	#arinpchg_work arinpchg, #arinptax_work arinptax, artxtype
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinptax.trx_ctrl_num
	AND	arinpchg.trx_type = arinptax.trx_type
	AND	arinptax.tax_type_code = artxtype.tax_type_code
	AND	arinpchg.recurring_flag != 3
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmctd.cpp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	






	CREATE TABLE #cdt_tax_sums
	(
		trx_ctrl_num	varchar(16),
		amt_tax_included	float
	)

	INSERT	#cdt_tax_sums
	SELECT	chg.trx_ctrl_num,
		SUM(cdt.calc_tax)
	FROM	#arinpchg_work chg, #arinpcdt_work cdt, artax tax
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	chg.trx_ctrl_num = cdt.trx_ctrl_num
	AND	cdt.tax_code = tax.tax_code
	AND	tax.tax_included_flag = 1
	GROUP BY chg.trx_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmctd.cpp" + ", line " + STR( 135, 5 ) + " -- EXIT: "
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
	SELECT	chg.date_applied,			dbo.IBAcctMask_fn(acct.tax_rounding_acct_code,chg.org_id),	
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			cdt.amt_tax_included - chg.amt_tax_included,			
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,			chg.trx_type,				
		0,					chg.trx_ctrl_num,
                chg.org_id    
	FROM	#arinpchg_work chg, #cdt_tax_sums cdt, glcurr_vw gl, araccts acct
	WHERE	chg.trx_ctrl_num = cdt.trx_ctrl_num
	AND	chg.nat_cur_code = gl.currency_code
	AND	chg.posting_code = acct.posting_code
	AND	ABS(ROUND(cdt.amt_tax_included - chg.amt_tax_included, gl.curr_precision)) >= gl.rounding_factor	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmctd.cpp" + ", line " + STR( 168, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	DROP TABLE #cdt_tax_sums

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmctd.cpp", 174, "Leaving ARCMCreateTaxDetails_SP", @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateTaxDetails_SP] TO [public]
GO
