SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC	[dbo].[arinvccr_sp]	@batch_ctrl_num	varchar( 16 ),
				@process_ctrl_num	varchar( 16 ),
				@debug_level		smallint = 0,
				@perf_level		smallint = 0
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	
	@result 		int,
	@last_trx_ctrl 	varchar( 16 ), 
	@min_trx_ctrl_num	varchar( 16),
	@trx_ctrl_num		varchar( 16),
	@customer_code	varchar( 8 ),
	@trx_type 		smallint
	
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinvccr.sp", 74, "Entering arincccr_sp", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvccr.sp" + ", line " + STR( 77, 5 ) + " -- ENTRY: "
	
	SELECT	@last_trx_ctrl = "", 
		@trx_ctrl_num = ""

	
	WHILE ( 1 = 1 )
	BEGIN
	 	SELECT @last_trx_ctrl = @trx_ctrl_num
		SELECT @trx_ctrl_num = NULL
		
		SELECT	@min_trx_ctrl_num = MIN(trx_ctrl_num)
		FROM	#arinpchg_work
		WHERE	batch_code = @batch_ctrl_num
	 	AND	trx_ctrl_num > @last_trx_ctrl
		AND	amt_paid > 0.0
		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvccr.sp" + ", line " + STR( 97, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		SELECT @trx_ctrl_num = trx_ctrl_num, 
			@trx_type = trx_type,
			@customer_code = customer_code
		FROM	#arinpchg_work
		WHERE	trx_ctrl_num = @min_trx_ctrl_num
		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvccr.sp" + ", line " + STR( 108, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		IF( @trx_ctrl_num IS NULL )
			BREAK

		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvccr.sp" + ", line " + STR( 115, 5 ) + " -- MSG: " + "Creating payments for transactions " + @trx_ctrl_num
		EXEC @result = arinvcr_sp	@batch_ctrl_num,
						@process_ctrl_num,
						@trx_type,	
						@trx_ctrl_num,	
						@customer_code,	
						@debug_level,
						@perf_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvccr.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END		

	
	UPDATE	#arinptmp_work			
	SET	db_action = arinptmp.db_action | 4
	FROM	#arinpchg_work arinpchg, #arinptmp_work arinptmp
	WHERE	batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinptmp.trx_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvccr.sp" + ", line " + STR( 143, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinvccr.sp", 147, "Leaving arinvccr_sp", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvccr.sp" + ", line " + STR( 148, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[arinvccr_sp] TO [public]
GO
