SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APDMUpdateTables_sp]
									@batch_ctrl_num		varchar(16),
									@debug_level		smallint = 0

AS

DECLARE
	@process_group_num 	varchar(16),
	@sys_date           int,
	@period_end         int,
	@errbuf             varchar(100),
	@client_id 			varchar(20),
	@user_id			int,  
	@batch_type			smallint,
    @result 			int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmut.cpp" + ", line " + STR( 95, 5 ) + " -- ENTRY: "

	SELECT  @user_id = NULL,
			@client_id = "APPOSTING"

    EXEC @result = batinfo_sp  	@batch_ctrl_num,
							  	@process_group_num 	OUTPUT,
								@user_id		OUTPUT,
								@sys_date		OUTPUT,
								@period_end		OUTPUT,
								@batch_type		OUTPUT
	IF( @result != 0 )
		RETURN -1


	



	BEGIN TRAN final_state
  












	




	EXEC @result = APDMUpdatePersistant_sp	@batch_ctrl_num,
											@process_group_num,
											@client_id,
											@user_id,
											@debug_level
	IF( @result	!= 0 )
	BEGIN
		ROLLBACK TRAN final_state
		RETURN @result
	END







	EXEC	@result = batupdst_sp	@batch_ctrl_num, 1
	IF(@result != 0)
			RETURN -1


	DECLARE @count INTEGER
	DECLARE @amt_net FLOAT

	SET @count = (SELECT COUNT(1) FROM #apdmchg_work)
	SET @amt_net = (SELECT ISNULL(SUM(amt_net),0.0) FROM #apdmchg_work)

	UPDATE pbatch
	SET end_number = @count,
		end_total = @amt_net,
		end_time = getdate(),
		flag = 2
	WHERE batch_ctrl_num = @batch_ctrl_num
	AND process_ctrl_num = @process_group_num


	COMMIT TRAN final_state

	







	EXEC ap_dm_sp @batch_ctrl_num

	
	







	RETURN 0

GO
GRANT EXECUTE ON  [dbo].[APDMUpdateTables_sp] TO [public]
GO
