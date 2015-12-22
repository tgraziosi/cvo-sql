SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[ARINUpdateTables_SP] @batch_ctrl_num varchar( 16 ),  @debug_level smallint = 0, 
 @perf_level smallint = 0 AS    DECLARE  @PERF_time_last datetime SELECT @PERF_time_last = GETDATE() 
   DECLARE  @result int,  @process_ctrl_num varchar(16),  @process_user_id smallint, 
 @company_code varchar(8),  @process_date int,  @period_end int,  @batch_type smallint, 
 @tran_started smallint IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\arinut.sp", 182, "Entering ARINUpdateTables_SP", @PERF_time_last OUTPUT 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 185, 5 ) + " -- ENTRY: " 
 IF ( @debug_level > 2 )  BEGIN  SELECT "dumping #artrx_work..."  SELECT "trx_ctrl_num = " + trx_ctrl_num + 
 "trx_type = " + STR(trx_type, 5)+  "amt_net = " + STR(amt_net, 10, 2 ) +  "batch_code = " + batch_code 
 FROM #artrx_work  END      EXEC @result = ARINUpdateTempStatistics_SP @batch_ctrl_num, 
 @debug_level,  @perf_level  IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 206, 5 ) + " -- EXIT: " 
 RETURN @result  END      EXEC @result = batinfo_sp @batch_ctrl_num,  @process_ctrl_num OUTPUT, 
 @process_user_id OUTPUT,  @process_date OUTPUT,  @period_end OUTPUT,  @batch_type OUTPUT 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 221, 5 ) + " -- EXIT: " 
 RETURN 35011  END      SELECT @company_code = company_code  FROM glco  IF( @@error != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 233, 5 ) + " -- EXIT: " 
 RETURN 34563  END      IF( @@trancount = 0 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 242, 5 ) + " -- MSG: " + "Beginning Transaction" 
 BEGIN TRAN  SELECT @tran_started = 1  END  EXEC @result = ARINUpdatePersistant_SP @batch_ctrl_num, 
 @process_ctrl_num,  @company_code,  @process_user_id,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 258, 5 ) + " -- MSG: " + "Rolling Back transaction" 
 ROLLBACK TRAN  SELECT @tran_started = 0  END  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 262, 5 ) + " -- EXIT: " 
 RETURN @result  END  UPDATE pbatch  SET end_number = (SELECT COUNT(*)  FROM #artrx_work 
 WHERE trx_type >= 2021  AND trx_type <= 2031  AND batch_code = @batch_ctrl_num  ), 
 end_total = ( SELECT ISNULL(SUM(amt_net),0.0)  FROM #artrx_work  WHERE trx_type >= 2021 
 AND trx_type <= 2031  AND batch_code = @batch_ctrl_num  ),  end_time = getdate(), 
 flag = 2  WHERE batch_ctrl_num = @batch_ctrl_num  AND process_ctrl_num = @process_ctrl_num 
 IF( @@error != 0 )  BEGIN  IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 287, 5 ) + " -- MSG: " + "Rolling Back transaction" 
 ROLLBACK TRAN  SELECT @tran_started = 0  END  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 291, 5 ) + " -- EXIT: " 
 RETURN 34563  END  IF( @tran_started = 1 )  BEGIN  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 297, 5 ) + " -- MSG: " + "Commiting Transaction" 
 COMMIT TRAN  SELECT @tran_started = 0  END          EXEC ar_inv_sp @batch_ctrl_num 
        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinut.sp" + ", line " + STR( 320, 5 ) + " -- EXIT: " 
 IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\arinut.sp", 321, "Entering ARINUpdateTables_SP", @PERF_time_last OUTPUT 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[ARINUpdateTables_SP] TO [public]
GO
