SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCreateRevenueDetails_SP]	@batch_ctrl_num     varchar( 16 ),
						@debug_level        smallint = 0,
						@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcRD.cpp", 83, "Entering ARCMCreateRevenueDetails_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcRD.cpp" + ", line " + STR( 86, 5 ) + " -- ENTRY: "

	INSERT	#argldist
	(
		date_applied,			account_code,			
                description,        		document_1,			document_2,
		nat_balance,							
                nat_cur_code,			
		rate_home,			trx_type,			seq_ref_id,			
		trx_ctrl_num,			rate_type_home,		rate_type_oper,		
		rate_oper,			reference_code,                 org_id         
	)
	SELECT	arinpchg.date_applied,	        dbo.IBAcctMask_fn(arinpcdt.gl_rev_acct,arinpcdt.org_id),	        
                arinpchg.doc_desc,              arinpchg.customer_code,	        arinpchg.doc_ctrl_num,
		arinpcdt.extended_price + arinpcdt.discount_amt - (tax.tax_included_flag * arinpcdt.calc_tax),		
                nat_cur_code,			
		arinpchg.rate_home,		arinpchg.trx_type,		arinpcdt.sequence_id,	
		arinpchg.trx_ctrl_num,	arinpchg.rate_type_home,	arinpchg.rate_type_oper,	
		arinpchg.rate_oper,		arinpcdt.reference_code,        arinpcdt.org_id 
	FROM	#arinpchg_work arinpchg, #arinpcdt_work arinpcdt, artax tax
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinpcdt.trx_ctrl_num
	AND	arinpchg.trx_type = arinpcdt.trx_type
	AND	arinpchg.recurring_flag = 1	
	AND	arinpcdt.tax_code = tax.tax_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcRD.cpp" + ", line " + STR( 113, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcRD.cpp", 117, "Leaving ARCMCreateRevenueDetails_SP", @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateRevenueDetails_SP] TO [public]
GO
