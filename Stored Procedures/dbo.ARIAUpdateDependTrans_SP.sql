SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAUpdateDependTrans_SP]	@batch_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariaudt.sp", 55, "Entering ARIAUpdateDependTrans", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaudt.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "
	
	
	UPDATE	#artrx_work
	SET	posted_flag = 1,
		db_action = #artrx_work.db_action | 1
	FROM	#arinpchg_work a
	WHERE	#artrx_work.trx_ctrl_num = a.trx_ctrl_num
	AND	#artrx_work.trx_type = a.trx_type
	AND	a.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaudt.sp" + ", line " + STR( 73, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	
	UPDATE	#artrxcdt_work
	SET	gl_rev_acct = cdt.new_gl_rev_acct,
		reference_code = cdt.new_reference_code,
		db_action = a.db_action | 1
	FROM	#artrxcdt_work a, #arinpcdt_work cdt, #arinpchg_work chg
	WHERE	a.doc_ctrl_num = chg.apply_to_num
	AND	a.trx_type = chg.apply_trx_type
	AND	cdt.trx_ctrl_num = chg.trx_ctrl_num
	AND	cdt.trx_type = chg.trx_type
	AND	a.sequence_id = cdt.sequence_id
	AND	chg.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaudt.sp" + ", line " + STR( 95, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	IF (@debug_level > 2)
	BEGIN
		SELECT "#######################################"
		SELECT 	" trx_ctrl_num = " + trx_ctrl_num +
				" doc_ctrl_num = " + doc_ctrl_num +
				" sequence_id = " + STR(sequence_id,2) +
				" trx_type = " + STR(trx_type,6) +
				" gl_rev_acct = " + gl_rev_acct	+
				" new_gl_rev_acct = " + new_gl_rev_acct +
				" reference_code = " + reference_code +
				" new_reference_code = " + new_reference_code
		FROM #artrxcdt_work

	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaudt.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/ariaudt.sp", 118, "Leaving ARIAUpdateDependantTrans_SP", @PERF_time_last OUTPUT
 RETURN 0 

END 

GO
GRANT EXECUTE ON  [dbo].[ARIAUpdateDependTrans_SP] TO [public]
GO
