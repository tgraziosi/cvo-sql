SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROC [dbo].[APPAUpdateTables_sp]
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appaut.cpp" + ", line " + STR( 79, 5 ) + " -- ENTRY: "

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

	



	EXEC @result = bows_ap_after_postPaymAdj_sp	@batch_ctrl_num,
											@debug_level
	IF( @result	!= 0 ) 
	BEGIN
		ROLLBACK TRAN final_state
		RETURN @result
	END
	
	




	EXEC @result = APPAUpdatePersistant_sp	@batch_ctrl_num,
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

	
	UPDATE pbatch
	SET end_number = (SELECT COUNT(*) FROM #appapyt_work),
		end_total = (SELECT ISNULL(SUM(amt_payment),0.0) FROM #appapyt_work),
		end_time = getdate(),
		flag = 2
	WHERE batch_ctrl_num = @batch_ctrl_num
	AND process_ctrl_num = @process_group_num

	COMMIT TRAN final_state

	RETURN 0 

GO
GRANT EXECUTE ON  [dbo].[APPAUpdateTables_sp] TO [public]
GO
