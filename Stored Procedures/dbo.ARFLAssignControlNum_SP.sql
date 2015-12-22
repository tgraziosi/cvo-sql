SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 



































































































































































































































































































 




















































































































































































































































































































CREATE PROC [dbo].[ARFLAssignControlNum_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint = 0,
						@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
 	@result		int,
	@new_ctrl_num		varchar(16),
	@num			int,
	@type			int,
	@apply_to_num		varchar(16),
	@apply_trx_type	int,
	@sub_apply_num	varchar(16),
	@sub_apply_type	int,
	@date_aging		int,
	@trx_type		int,
	@customer_code	varchar(8)	

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflacn.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflacn.sp", 61, "Entering ARFLAssignControlNum_SP", @PERF_time_last OUTPUT
	
	
	WHILE ( 1 = 1 )
	BEGIN
		SET ROWCOUNT 1
								
		
		SELECT	@sub_apply_num = sub_apply_num,
			@sub_apply_type = sub_apply_type,
			@date_aging = date_aging,
			@customer_code = customer_code
		FROM	#artrxage_work
		WHERE	( LTRIM(trx_ctrl_num) IS NULL OR LTRIM(trx_ctrl_num) = " " )
		
		IF ( @@rowcount = 0 )
		BEGIN	
			SET ROWCOUNT 0
			BREAK
		END
		
		SET ROWCOUNT 0
		
		IF ( @debug_level > 0 )
		BEGIN
			SELECT "Looping...."
			SELECT	"sub_apply_num = " + @sub_apply_num
			SELECT	"sub_apply_type = " + STR(@sub_apply_type, 8)
			SELECT	"date_aging = " + STR(@date_aging, 8)
			SELECT	"customer_code = " + @customer_code
		END
			
		
		EXEC @result = ARGetNextControl_SP 2040,
							@new_ctrl_num OUTPUT,
							@num OUTPUT,
							@debug_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflacn.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
			RETURN @result
		END
		
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflacn.sp" + ", line " + STR( 110, 5 ) + " -- MSG: " + "@new_ctrl_num = " + @new_ctrl_num
		
		UPDATE	#artrxage_work
		SET	trx_ctrl_num = @new_ctrl_num,
			doc_ctrl_num = @new_ctrl_num
		WHERE	sub_apply_num = @sub_apply_num
		AND	sub_apply_type = @sub_apply_type
		AND	customer_code = @customer_code
		AND	date_aging = @date_aging
		AND	trx_type = 2061
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflacn.sp" + ", line " + STR( 123, 5 ) + " -- EXIT: "
			RETURN 34563
		END

	END
	
	
	WHILE ( 1 = 1 )
	BEGIN
		SET ROWCOUNT 1
								
		
		SELECT	@customer_code = customer_code,
			@apply_to_num = apply_to_num,
			@apply_trx_type = apply_trx_type
		FROM	#artrx_work
		WHERE	( LTRIM(trx_ctrl_num) IS NULL OR LTRIM(trx_ctrl_num) = " " )
		
		IF ( @@rowcount = 0 )
		BEGIN	
			SET ROWCOUNT 0
			BREAK
		END
		
		SET ROWCOUNT 0
		
		IF ( @debug_level > 0 )
		BEGIN
			SELECT "Looping...."
			SELECT	"apply_to_num = " + @apply_to_num
			SELECT	"apply_trx_type = " + STR(@apply_trx_type, 8)
			SELECT	"customer_code = " + @customer_code
		END
			
		
		EXEC @result = ARGetNextControl_SP 2050,
							@new_ctrl_num OUTPUT,
							@num OUTPUT,
							@debug_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflacn.sp" + ", line " + STR( 170, 5 ) + " -- EXIT: "
			RETURN @result
		END
		
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflacn.sp" + ", line " + STR( 174, 5 ) + " -- MSG: " + "@new_ctrl_num = " + @new_ctrl_num
		
		IF ( ( LTRIM(@apply_to_num) IS NULL OR LTRIM(@apply_to_num) = " " ) )
			
		 	UPDATE	#artrx_work
			SET	trx_ctrl_num = @new_ctrl_num,
				doc_ctrl_num = @new_ctrl_num,
				apply_to_num = @new_ctrl_num
			WHERE	customer_code = @customer_code
			AND	( LTRIM(trx_ctrl_num) IS NULL OR LTRIM(trx_ctrl_num) = " " )
		ELSE
			UPDATE	#artrx_work
			SET	trx_ctrl_num = @new_ctrl_num,
				doc_ctrl_num = @new_ctrl_num
			WHERE	apply_to_num = @apply_to_num
			AND	apply_trx_type = @apply_trx_type
			AND	customer_code = @customer_code
			AND	trx_type = 2071
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflacn.sp" + ", line " + STR( 197, 5 ) + " -- EXIT: "
			RETURN 34563
		END

	END

 	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflacn.sp", 203, "Leaving ARFLAssignControlNum_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflacn.sp" + ", line " + STR( 204, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLAssignControlNum_SP] TO [public]
GO
