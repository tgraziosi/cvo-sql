SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCreateDiscTakenDetails_SP]	@batch_ctrl_num     varchar( 16 ),
						@debug_level        smallint = 0,
						@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcdtd.cpp", 56, "Entering ARCMCreateDiscTakenDetails_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcdtd.cpp" + ", line " + STR( 59, 5 ) + " -- ENTRY: "

	



	INSERT	#argldist
	(
		date_applied,			account_code,			description,
		document_1,			document_2,			nat_balance,
		nat_cur_code,			rate_home,			trx_type,
		seq_ref_id,			trx_ctrl_num,			rate_type_home,
		rate_type_oper,		        rate_oper,                      org_id        
	)
	SELECT	arinpchg.date_applied,	dbo.IBAcctMask_fn(acct.disc_taken_acct_code,arinpchg.org_id), 
                arinpchg.doc_desc,
		arinpchg.customer_code,	arinpchg.doc_ctrl_num,	        -arinpchg.amt_discount_taken,
		arinpchg.nat_cur_code,	rate_home,			arinpchg.trx_type,
		0,			arinpchg.trx_ctrl_num,	        rate_type_home,
		rate_type_oper,		rate_oper,                      arinpchg.org_id        
	FROM	#arinpchg_work arinpchg, araccts acct
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.posting_code = acct.posting_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcdtd.cpp" + ", line " + STR( 84, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcdtd.cpp", 88, "Leaving ARCMCreateDiscTakenDetails_SP", @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateDiscTakenDetails_SP] TO [public]
GO
