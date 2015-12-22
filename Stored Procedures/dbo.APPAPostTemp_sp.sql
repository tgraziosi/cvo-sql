SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APPAPostTemp_sp] 	@batch_ctrl_num varchar(16),
								@process_group_num 	varchar(16),
								@user_id				int, 
								@cm_exist 				smallint,
								@period_end 			int,
								@debug_level 			smallint = 0


AS
DECLARE @result int,
		@journal_ctrl_num varchar(16),
		@date_applied int


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appapt.sp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "

SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num



EXEC @result = APPAProcessGLEntries_sp @process_group_num,
										@date_applied,
										@batch_ctrl_num,
										@user_id,
										@journal_ctrl_num OUTPUT,
										@debug_level

IF (@result != 0)
 RETURN @result



IF (@cm_exist = 1)
 BEGIN
	EXEC @result = APPAProcessCMEntries_sp @date_applied, @debug_level
	IF (@result != 0)
	 RETURN @result


 END


IF EXISTS (SELECT * FROM #appapyt_work 
		 WHERE void_type = 2)
	BEGIN
		EXEC @result = APPAProcessDebitMemos_sp @user_id, 
												@debug_level
		IF (@result != 0)
 		RETURN @result
 END


IF EXISTS (SELECT * FROM #appapyt_work 
		 WHERE void_type = 5)
	BEGIN
		EXEC @result = APPAProcessPayments_sp @user_id,
												@debug_level
		IF (@result != 0)
 		RETURN @result
 END



EXEC @result = APPAUpdatePostedRecords_sp @journal_ctrl_num,
										 @debug_level
IF (@result != 0)
	 RETURN @result


EXEC @result = APPAInsertPostedRecords_sp 	@journal_ctrl_num,
											@date_applied,
											@debug_level
IF (@result != 0)
	 RETURN @result



EXEC @result = APPAVendorActSum_sp	@debug_level

IF @result != 0
	 RETURN @result


EXEC @result = APPADeleteInputTables_sp	@debug_level

IF @result != 0
	 RETURN @result





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appapt.sp" + ", line " + STR( 150, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPAPostTemp_sp] TO [public]
GO
