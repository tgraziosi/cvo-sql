SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




























CREATE PROCEDURE [dbo].[apgenfin_sp]
	@user_id smallint, 
	@process_group_num varchar(16),
	@batch_code varchar(16),
	@debug_level smallint = 0
AS
DECLARE @trx_ctrl_num varchar(16), 
		@last_ctrl_num varchar(16), 
		@result smallint, 
		@userstring varchar(80),
		@aprv_check_flag smallint,
		@current_date int,
		@count int,
		@process_type smallint


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgenfin.sp" + ", line " + STR( 80, 5 ) + " -- ENTRY: "

SELECT @count = count(*) FROM #apinppyt

SELECT @process_type = process_type 
FROM pcontrol_vw
WHERE process_ctrl_num = @process_group_num


IF @count < 1 
 BEGIN
	UPDATE apvohdr
	SET state_flag = 1,
		process_ctrl_num = " "
	WHERE state_flag = -1
	AND process_ctrl_num = @process_group_num

	IF @process_type = 4998
		UPDATE appyhdr
		SET state_flag = 1,
			process_ctrl_num = " "
		WHERE state_flag = -1
		AND process_ctrl_num = @process_group_num


	EXEC @result = pctrlust_sp @process_group_num, "0" 
	IF @result <> 0
 		BEGIN
		 ROLLBACK TRAN
 	 RETURN @result 
	 END

	RETURN 0
 END


SELECT @aprv_check_flag = aprv_check_flag
FROM apco


IF ( @aprv_check_flag = 1 )
 BEGIN
	 SELECT trx_ctrl_num
	 INTO #temp1
	 FROM #apinppyt
 END

EXEC appdate_sp @current_date OUTPUT


BEGIN TRAN


IF (@count > 0)
 BEGIN

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgenfin.sp" + ", line " + STR( 136, 5 ) + " -- MSG: " + "---Calling payment save routine"

		IF @batch_code = ""
		 SELECT @batch_code = NULL

		EXEC @result = appysav_sp @user_id, @batch_code, @debug_level
		IF @result<>0
		 BEGIN
			 ROLLBACK TRAN
		 RETURN @result 
		 END 


IF ( @aprv_check_flag = 1 )
BEGIN

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgenfin.sp" + ", line " + STR( 155, 5 ) + " -- MSG: " + "---Creating approvals"

	SELECT @last_ctrl_num = ' '
	WHILE ( 1 = 1 )
	BEGIN
		SELECT @trx_ctrl_num = NULL

		
		SELECT @trx_ctrl_num = MIN( trx_ctrl_num )
		FROM #temp1
		WHERE trx_ctrl_num > @last_ctrl_num

		IF ( @trx_ctrl_num IS NULL )
			BREAK

		SELECT @last_ctrl_num = @trx_ctrl_num

		
		EXEC apaprmk_sp 4111, @trx_ctrl_num, @current_date
	END
END


END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgenfin.sp" + ", line " + STR( 185, 5 ) + " -- MSG: " + "---Reseting aptrx"

UPDATE apvohdr
SET state_flag = 1,
	process_ctrl_num = " "
WHERE state_flag = -1
AND process_ctrl_num = @process_group_num

	IF @process_type = 4998
		UPDATE appyhdr
		SET state_flag = 1,
			process_ctrl_num = " "
		WHERE state_flag = -1
		AND process_ctrl_num = @process_group_num

SELECT @userstring = str(@count) 

EXEC @result = pctrlust_sp @process_group_num, @userstring 
IF @result <> 0
 BEGIN
	 ROLLBACK TRAN
 RETURN @result 
 END

COMMIT TRAN


IF ( @aprv_check_flag = 1 )
			DROP TABLE #temp1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apgenfin.sp" + ", line " + STR( 217, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apgenfin_sp] TO [public]
GO
