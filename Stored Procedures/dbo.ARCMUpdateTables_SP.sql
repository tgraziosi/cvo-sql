SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[ARCMUpdateTables_SP] @batch_ctrl_num varchar( 16 ),  @debug_level smallint = 0, 
 @perf_level smallint = 0 AS    DECLARE  @PERF_time_last datetime SELECT @PERF_time_last = GETDATE() 
   DECLARE  @result int,  @process_ctrl_num varchar( 16 ),  @process_user_id smallint, 
 @company_code varchar( 8 ),  @process_date int,  @period_end int,  @batch_type smallint, 
 @tran_started smallint IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\arcmut.sp", 165, "Entering ARCMUpdateTables_SP", @PERF_time_last OUTPUT 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 168, 5 ) + " -- ENTRY: " 
     EXEC @result = batinfo_sp @batch_ctrl_num,  @process_ctrl_num OUTPUT,  @process_user_id OUTPUT, 
 @process_date OUTPUT,  @period_end OUTPUT,  @batch_type OUTPUT  IF( @result != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 182, 5 ) + " -- EXIT: " 
 RETURN 35011  END      SELECT @company_code = company_code  FROM glco      EXEC @result = ARCMUpdateTempStatistics_SP @batch_ctrl_num, 
 @debug_level,  @perf_level  IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 200, 5 ) + " -- EXIT: " 
 RETURN @result  END      IF( @@trancount = 0 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 209, 5 ) + " -- MSG: " + "Beginning Transaction" 
 BEGIN TRAN  SELECT @tran_started = 1  END      EXEC @result = arpysav_sp @company_code, 
 @process_user_id  IF( @result != 0 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 222, 5 ) + " -- MSG: " + "arpysav_sp failed: " + STR(@result, 6 ) 
 IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 225, 5 ) + " -- MSG: " + "Rolling Back transaction" 
 ROLLBACK TRAN  SELECT @tran_started = 0  END  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 229, 5 ) + " -- EXIT: " 
 RETURN 34562  END  EXEC @result = ARCMModifyPersistant_SP @batch_ctrl_num,  @debug_level, 
 @perf_level  IF( @result != 0 )  BEGIN  IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 241, 5 ) + " -- MSG: " + "Rolling Back transaction" 
 ROLLBACK TRAN  SELECT @tran_started = 0  END  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 245, 5 ) + " -- EXIT: " 
 RETURN @result  END      EXEC @result = batupdst_sp @batch_ctrl_num, 1  IF( @result != 0 ) 
 BEGIN  IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 258, 5 ) + " -- MSG: " + "Rolling Back transaction" 
 ROLLBACK TRAN  SELECT @tran_started = 0  END  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 262, 5 ) + " -- EXIT: " 
 RETURN 34562  END       EXEC @result = gltrxsav_sp @process_ctrl_num,  @company_code 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 274, 5 ) + " -- MSG: " + "gltrxsav_sp failed: " + STR(@result, 6 ) 
 IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 277, 5 ) + " -- MSG: " + "Rolling Back transaction" 
 ROLLBACK TRAN  SELECT @tran_started = 0  END  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 281, 5 ) + " -- EXIT: " 
 RETURN 34562  END  UPDATE pbatch  SET end_number = (SELECT COUNT(*)  FROM #artrx_work 
 WHERE trx_type = 2032  AND batch_code = @batch_ctrl_num  ),  end_total = (SELECT ISNULL(SUM(amt_net),0.0) 
 FROM #artrx_work  WHERE trx_type = 2032  AND batch_code = @batch_ctrl_num  ),  end_time = getdate(), 
 flag = 2  WHERE batch_ctrl_num = @batch_ctrl_num  AND process_ctrl_num = @process_ctrl_num 
 IF ( @@error != 0 )  BEGIN  IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 305, 5 ) + " -- MSG: " + "Rolling Back transaction" 
 ROLLBACK TRAN  SELECT @tran_started = 0  END  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 309, 5 ) + " -- EXIT: " 
 RETURN 34562  END  IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 315, 5 ) + " -- MSG: " + "Commiting Transaction" 
 COMMIT TRAN  SELECT @tran_started = 0  END          EXEC ar_cr_sp @batch_ctrl_num 
        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcmut.sp" + ", line " + STR( 338, 5 ) + " -- EXIT: " 
 IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\arcmut.sp", 339, "Exiting ARCMUpdateTables_SP", @PERF_time_last OUTPUT 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[ARCMUpdateTables_SP] TO [public]
GO
