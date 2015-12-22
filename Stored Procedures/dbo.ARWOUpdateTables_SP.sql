SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOUpdateTables_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int,
	@process_ctrl_num	varchar(16),
	@process_user_id	smallint,
	@company_code		varchar(8),
	@process_date		int,
	@period_end		int,
	@batch_type		smallint,
	@tran_started		smallint


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwout.sp", 105, "Entering ARWOUpdateTables_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 108, 5 ) + " -- ENTRY: "

	
	EXEC @result = ARModifyPersistant_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF(@result != 0 )
	BEGIN
		IF( @tran_started = 1 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 121, 5 ) + " -- MSG: " + "Rolling Back transaction"
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@process_user_id OUTPUT,
					@process_date OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 140, 5 ) + " -- MSG: " + "batinfo error: @result = " + STR(@result, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	
	IF EXISTS 	(	
			SELECT * 
			FROM 	batchctl 
			WHERE	batch_ctrl_num = @batch_ctrl_num 
			AND	hold_flag = 0
			)
	BEGIN
		
		EXEC @result = batupdst_sp	@batch_ctrl_num,
						1
		IF(@result != 0 )
		BEGIN
			IF( @tran_started = 1 )
			BEGIN
				IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 162, 5 ) + " -- MSG: " + "Rolling Back transaction"
				ROLLBACK TRAN
				SELECT	@tran_started = 0
			END
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 166, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	
	SELECT	@company_code = company_code
	FROM	glco

	
	IF( @@trancount = 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 182, 5 ) + " -- MSG: " + "Beginning Transaction"
		BEGIN TRAN 
		SELECT	@tran_started = 1
	END

	
	EXEC @result = gltrxsav_sp	@process_ctrl_num,
					@company_code
	IF(@result != 0 )
	BEGIN
		IF( @tran_started = 1 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 196, 5 ) + " -- MSG: " + "Rolling Back transaction"
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 200, 5 ) + " -- EXIT: "
		RETURN @result
	END

	UPDATE pbatch
	SET 	end_number = (SELECT COUNT(*) FROM #artrxpdt_work),
		end_total = (SELECT ISNULL(SUM(amt_wr_off),0.0) FROM #artrxpdt_work),
		end_time = getdate(),
		flag = 2
	WHERE 	batch_ctrl_num = @batch_ctrl_num
	AND 	process_ctrl_num = @process_ctrl_num

	
	IF( @tran_started = 1 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 217, 5 ) + " -- MSG: " + "Commiting Transaction"
		COMMIT TRAN
		SELECT	@tran_started = 0
	END


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arwout.sp" + ", line " + STR( 223, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arwout.sp", 224, "Entering ARWOUpdateTables_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARWOUpdateTables_SP] TO [public]
GO
