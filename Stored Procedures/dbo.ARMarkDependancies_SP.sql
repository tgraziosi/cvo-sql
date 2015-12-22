SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

   CREATE PROC [dbo].[ARMarkDependancies_SP] @batch_ctrl_num varchar( 16 ),  @process_ctrl_num varchar( 16 ), 
 @all_trx_marked smallint OUTPUT,  @debug_level smallint = 0,  @perf_level smallint = 0 
AS BEGIN    DECLARE  @PERF_time_last datetime SELECT @PERF_time_last = GETDATE() 
    DECLARE @tran_started smallint,  @status int  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armd.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: " 
 IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armd.sp" + ", line " + STR( 56, 5 ) + " -- MSG: " + "Entering ARMarkDependancies_SP" 
 IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armd.sp" + ", line " + STR( 57, 5 ) + " -- MSG: " + "@batch_ctrl_num: " + @batch_ctrl_num 
 IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armd.sp" + ", line " + STR( 58, 5 ) + " -- MSG: " + "@all_trx_marked: " + STR( @all_trx_marked, 3 ) 
 IF ( @debug_level > 3 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armd.sp" + ", line " + STR( 59, 5 ) + " -- MSG: " + "@debug_level: " + STR( @debug_level, 3 ) 
 IF ( @debug_level > 3 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armd.sp" + ", line " + STR( 60, 5 ) + " -- MSG: " + "@perf_level: " + STR( @perf_level, 3 ) 
 SELECT @tran_started = 0,  @status = 0  IF ( @debug_level > 5 )  BEGIN  SELECT "#deplock" 
 SELECT customer_code + doc_ctrl_num + STR(trx_type, 10) +  STR(lock_status, 10) + STR(temp_flag, 10) 
 FROM #deplock  END  IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 74, "entry ARMarkDependancies", @PERF_time_last OUTPUT 
 IF( @@trancount = 0 )  BEGIN  BEGIN TRAN armark  SELECT @tran_started = 1  END   
      UPDATE artrx  SET posted_flag = -1,  process_group_num = @process_ctrl_num 
 FROM artrx a, #deplock b  WHERE a.trx_type = b.trx_type  AND a.doc_ctrl_num = b.doc_ctrl_num 
 AND a.customer_code = b.customer_code  AND a.posted_flag = 1  AND a.payment_type in (0, 1, 3) 
 AND a.void_flag = 0  IF @@error != 0  SELECT @status = 34555  IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 103, "update artrx", @PERF_time_last OUTPUT 
 IF( @status = 0 )  BEGIN      UPDATE artrx  SET posted_flag = -1,  process_group_num = @process_ctrl_num 
 FROM artrx a, #deplock b  WHERE a.apply_trx_type = b.trx_type  AND a.apply_to_num = b.doc_ctrl_num 
 AND a.customer_code = b.customer_code  AND a.posted_flag = 1  AND a.trx_type <= 2032 
 AND a.void_flag = 0  IF @@error != 0  SELECT @status = 34555  IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 125, "update artrx subordinates", @PERF_time_last OUTPUT 
 END      IF @status = 0  BEGIN  UPDATE #deplock  SET lock_status = 1  IF @@error != 0 
 SELECT @status = 34556  IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 141, "update #deplock", @PERF_time_last OUTPUT 
 END        IF ( @status = 0 )  BEGIN  UPDATE #deplock  SET lock_status = 0  FROM artrx a, #deplock b 
 WHERE a.doc_ctrl_num = b.doc_ctrl_num  AND a.trx_type = b.trx_type  AND a.customer_code = b.customer_code 
 AND a.payment_type in (0, 1, 3)  AND a.process_group_num != @process_ctrl_num  AND a.void_flag = 0 
 IF @@error != 0  SELECT @status = 34556            IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 178, "update #deplock", @PERF_time_last OUTPUT 
 UPDATE #deplock  SET lock_status = 0  FROM artrx a, #deplock b  WHERE a.apply_to_num = b.doc_ctrl_num 
 AND a.apply_trx_type = b.trx_type  AND a.customer_code = b.customer_code  AND a.trx_type <= 2032 
 AND a.process_group_num != @process_ctrl_num  AND ( LTRIM(a.process_group_num) IS NOT NULL AND LTRIM(a.process_group_num) != " " ) 
 AND a.void_flag = 0  IF @@error != 0  SELECT @status = 34556  IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 195, "update #deplock", @PERF_time_last OUTPUT 
 END       IF ( @status = 0 )  BEGIN  UPDATE artrx  SET posted_flag = 1  FROM artrx a, #deplock b 
 WHERE a.doc_ctrl_num = b.doc_ctrl_num  AND a.trx_type = b.trx_type  AND a.customer_code = b.customer_code 
 AND b.lock_status = 0  AND a.process_group_num = @process_ctrl_num  IF @@error != 0 
 SELECT @status = 34555  IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 219, "update artrx", @PERF_time_last OUTPUT 
 END      IF ( @status = 0 )  IF EXISTS ( SELECT lock_status  FROM #deplock  WHERE lock_status != 1 ) 
 SELECT @all_trx_marked = 0  ELSE  SELECT @all_trx_marked = 1  IF ( @@error != 0 ) 
 SELECT @status = 34557  IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 237, "check if all XACs were locked", @PERF_time_last OUTPUT 
 IF @status != 0  BEGIN  IF( @tran_started = 1 )  ROLLBACK TRAN armark  SELECT @all_trx_marked = 0 
 END  ELSE  BEGIN  IF( @tran_started = 1 )  COMMIT TRAN armark  END  IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armd.sp", 252, "exit ARMarkDependancies_SP", @PERF_time_last OUTPUT 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armd.sp" + ", line " + STR( 254, 5 ) + " -- EXIT: " 
 RETURN @status END 
GO
GRANT EXECUTE ON  [dbo].[ARMarkDependancies_SP] TO [public]
GO
