SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCRUpdateTables_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result				int,
	@process_ctrl_num	varchar( 16 ),
	@process_user_id	smallint,
	@company_code		varchar( 8 ),
	@process_date		int,
	@period_end			int,
	@batch_type			smallint,
	@tran_started		smallint,
 /* Begin mod: CB0001 */
 @min_cust varchar(8),
 @last_cust varchar(8)
 /* End mod: CB0001 */


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrut.sp", 111, "Entering ARCRUpdateTables_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrut.sp" + ", line " + STR( 114, 5 ) + " -- ENTRY: "
	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
								@process_ctrl_num OUTPUT,
								@process_user_id OUTPUT,
								@process_date OUTPUT,
								@period_end OUTPUT,
								@batch_type OUTPUT
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrut.sp" + ", line " + STR( 126, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	
	SELECT	@company_code = company_code
	FROM	glco

	
	EXEC @result = ARCRUpdateStatisticsTemp_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrut.sp" + ", line " + STR( 148, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	IF( @@trancount = 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrut.sp" + ", line " + STR( 157, 5 ) + " -- MSG: " + "Beginning Transaction"
		BEGIN TRAN 
		SELECT	@tran_started = 1
	END

	
	EXEC @result = ARCRUpdatePersistant_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@company_code,
							@process_user_id,
							@debug_level,
							@perf_level
	IF(@result != 0 )
	BEGIN
		IF( @tran_started = 1 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrut.sp" + ", line " + STR( 177, 5 ) + " -- MSG: " + "Rolling Back transaction"
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrut.sp" + ", line " + STR( 181, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @debug_level > 2 )
	BEGIN
		SELECT "dumping #artrx_work..."
		SELECT "trx_ctrl_num = " + trx_ctrl_num +
			"trx_type = " + STR(trx_type, 5)+
			"amt_net = " + STR(amt_net, 10, 2 ) +
			"amt_on_acct = " + STR(amt_on_acct, 10, 2) +
			"batch_code = " + batch_code
		FROM	#artrx_work
	END
	
	UPDATE pbatch
	SET 	end_number = (SELECT COUNT(*) 
				FROM 	#artrx_work
				WHERE	trx_type = 2111
				AND	batch_code = @batch_ctrl_num
			 	),
		end_total = (	SELECT ISNULL(SUM(amt_net),0.0) 
				FROM 	#artrx_work
				WHERE	trx_type = 2111
				AND	batch_code = @batch_ctrl_num
				),
		end_time = getdate(),
		flag = 2
	WHERE 	batch_ctrl_num = @batch_ctrl_num
	AND 	process_ctrl_num = @process_ctrl_num
	
	IF( @tran_started = 1 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrut.sp" + ", line " + STR( 214, 5 ) + " -- MSG: " + "Commiting Transaction"
		COMMIT TRAN
		SELECT	@tran_started = 0
	END

	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN

		/* Begin mod: CB0001 - Update customer activity and summary */
		/*EXEC aractsum_sp 1, 1, 0, 0, 0, 1, 1, 0, 0, 0 */
		SELECT @min_cust = "",
		       @last_cust = ""
		WHILE 1=1
		BEGIN
			SELECT @min_cust = MIN(customer_code)
			FROM #artrx_work
			WHERE	customer_code > @last_cust
	
			IF @min_cust IS NULL BREAK
	
			SELECT @last_cust = @min_cust
	
			EXEC ARCBUPDateCustSummary_SP 	@min_cust
			EXEC ARCBUPDateCustActivity_SP  @min_cust
		END
		/* End mod: CB0001 */
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrut.sp" + ", line " + STR( 219, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrut.sp", 220, "Entering ARCRUpdateTables_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCRUpdateTables_SP] TO [public]
GO
