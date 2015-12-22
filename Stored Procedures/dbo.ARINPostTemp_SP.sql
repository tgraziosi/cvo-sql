SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 










































































































































































































































































 































































































































































































































































































































































































































































































































































































































































 













































CREATE PROC [dbo].[ARINPostTemp_SP]	@batch_ctrl_num	varchar( 16 ),
					@process_ctrl_num	varchar( 16 ),
					@user_id 		smallint, 
					@debug_level		smallint,
					@perf_level		smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@trx_num			varchar( 16 ), 
	@trx_type 			smallint, 
	@journal_ctrl_num 		varchar( 16 ),
	@cust_code 			varchar( 8 ),
	@amt_paid 			float,	
	@last_trx_ctrl 		varchar( 16 ), 
	@result 			int, 
	@min_trx_ctrl_num		varchar( 16),
	@system_date			int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpt.sp", 160, "Entering ARINPostTemp_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 163, 5 ) + " -- ENTRY: "
	
	EXEC appdate_sp @system_date OUTPUT

	
	UPDATE	#arinpcdt_work
	SET	doc_ctrl_num = #arinpchg_work.doc_ctrl_num,
		db_action = #arinpcdt_work.db_action | 1
	FROM	#arinpchg_work
	WHERE	#arinpchg_work.batch_code = @batch_ctrl_num
	AND	#arinpchg_work.trx_ctrl_num = #arinpcdt_work.trx_ctrl_num
	AND	#arinpchg_work.trx_type = #arinpcdt_work.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 180, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	UPDATE	#arinpage_work
	SET	doc_ctrl_num = #arinpchg_work.doc_ctrl_num,
		apply_to_num = #arinpchg_work.doc_ctrl_num,
		apply_trx_type = #arinpchg_work.trx_type,
		db_action = #arinpage_work.db_action | 1
	FROM	#arinpchg_work
	WHERE	#arinpchg_work.batch_code = @batch_ctrl_num
	AND	#arinpchg_work.trx_ctrl_num = #arinpage_work.trx_ctrl_num
	AND	#arinpchg_work.trx_type = #arinpage_work.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 207, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#arinpage_work
	SET	apply_to_num = arinpchg.apply_to_num,
		apply_trx_type = arinpchg.apply_trx_type,
		db_action = #arinpage_work.db_action | 1
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = #arinpage_work.trx_ctrl_num
	AND	arinpchg.trx_type = #arinpage_work.trx_type
	AND	( LTRIM(arinpchg.apply_to_num) IS NOT NULL AND LTRIM(arinpchg.apply_to_num) != " " )
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 222, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#arinpchg_work
	SET	posted_flag = 1,
		apply_to_num = doc_ctrl_num,
		apply_trx_type = trx_type,
		db_action = db_action | 1		
	WHERE	#arinpchg_work.batch_code = @batch_ctrl_num
	AND	( LTRIM(apply_to_num) IS NULL OR LTRIM(apply_to_num) = " " )
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 238, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	
	EXEC @result = ARINCreateGLTransactions_SP	@batch_ctrl_num,
								@journal_ctrl_num OUTPUT,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 252, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARINApplyChildInvoices_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 265, 5 ) + " -- EXIT: "
		RETURN @result
	END

	EXEC @result = arinvstx_sp	@batch_ctrl_num,
					@debug_level,
					@perf_level
	IF (@result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 274, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinvrec_sp	@batch_ctrl_num,
					@process_ctrl_num,
					@system_date, 
					@debug_level,
					@perf_level
	IF (@result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 288, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARINUpdateInvoices_SP	@batch_ctrl_num,
							@journal_ctrl_num,
					 		@debug_level,
					 		@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 302, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = arinvccr_sp	@batch_ctrl_num,
					@process_ctrl_num,
					@debug_level,
					@perf_level
	IF ( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 322, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	EXEC @result = ARINUpdateActivitySummary_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 334, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinpt.sp", 338, "Leaving ARINPostTemp_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinpt.sp" + ", line " + STR( 339, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARINPostTemp_SP] TO [public]
GO
