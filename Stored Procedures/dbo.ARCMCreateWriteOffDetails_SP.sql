SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCreateWriteOffDetails_SP]	@batch_ctrl_num     varchar( 16 ),
						@debug_level        smallint = 0,
						@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcwod.cpp", 55, "Entering ARCMCreateWriteOffDetails_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcwod.cpp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "
	



	INSERT	#argldist
	(
		date_applied,			account_code,			description,
		document_1,			document_2,			nat_balance,
		nat_cur_code,			rate_home,			trx_type,
		seq_ref_id,			trx_ctrl_num,			rate_oper,
		rate_type_home,		        rate_type_oper,                 org_id        
	)
	SELECT	arinpchg.date_applied,	dbo.IBAcctMask_fn(wrof.writeoff_account,arinpchg.org_id),	arinpchg.doc_desc,
		arinpchg.customer_code,	arinpchg.doc_ctrl_num,	-arinpchg.amt_write_off_given,
		arinpchg.nat_cur_code,	arinpchg.rate_home,	arinpchg.trx_type,
		0,			arinpchg.trx_ctrl_num,	arinpchg.rate_oper,
		arinpchg.rate_type_home,arinpchg.rate_type_oper,arinpchg.org_id        
	FROM	#arinpchg_work arinpchg, arwrofac wrof, arinpchg arinp
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinp.trx_ctrl_num
	AND	arinpchg.trx_type = arinp.trx_type
	AND	arinp.writeoff_code = wrof.writeoff_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcwod.cpp" + ", line " + STR( 84, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcwod.cpp", 88, "Leaving ARCMCreateWriteOffDetails_SP", @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateWriteOffDetails_SP] TO [public]
GO
