SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[ARCAPostBatch_SP] @batch_ctrl_num varchar( 16 ),  @debug_level smallint = 0, 
 @perf_level smallint = 0 AS    DECLARE  @PERF_time_last datetime SELECT @PERF_time_last = GETDATE() 
   DECLARE  @result int,  @batch_proc_flag smallint,  @cm_flag smallint,  @process_ctrl_num varchar( 16 ), 
 @process_user_id smallint,  @process_date int,  @period_end int,  @batch_type smallint, 
 @journal_type varchar(8),  @company_code varchar(8),  @home_cur_code varchar(8), 
 @oper_cur_code varchar(8),  @validation_status int IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\arcapb.sp", 55, "Entering ARCAPostBatch_SP", @PERF_time_last OUTPUT 
BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: " 
 IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 59, 5 ) + " -- MSG: " + "batch_ctrl_num: " + @batch_ctrl_num 
 SELECT @process_ctrl_num = p.process_ctrl_num  FROM batchctl b, pcontrol_vw p  WHERE b.process_group_num = p.process_ctrl_num 
 AND b.batch_ctrl_num = @batch_ctrl_num  INSERT pbatch ( process_ctrl_num, batch_ctrl_num, 
 start_number, start_total,  end_number, end_total,  start_time, end_time,  flag 
 )  VALUES (  @process_ctrl_num, @batch_ctrl_num,  0, 0,  0, 0,  getdate(), NULL, 
 0  )       EXEC @result = ARCRInit_SP @batch_ctrl_num,  @batch_proc_flag OUTPUT, 
 @cm_flag OUTPUT,  @process_ctrl_num OUTPUT,  @process_user_id OUTPUT,  @process_date OUTPUT, 
 @period_end OUTPUT,  @batch_type OUTPUT,  @journal_type OUTPUT,  @company_code OUTPUT, 
 @home_cur_code OUTPUT,  @oper_cur_code OUTPUT,  @debug_level,  @perf_level  IF( @result != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: " 
 RETURN @result  END          EXEC @result = ARPYInsertTempTables_SP @process_ctrl_num, 
 @batch_ctrl_num,  @debug_level,  @perf_level  IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: " 
 RETURN @result  END        EXEC @result = ARCALockDependancies_SP @batch_ctrl_num, 
 @process_ctrl_num,  @batch_proc_flag,  @debug_level,  @perf_level  IF( @result != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 135, 5 ) + " -- EXIT: " 
 RETURN @result  END  IF( @result = 0 )  BEGIN  EXEC @result = ARCAInsertDependancies_SP @batch_ctrl_num, 
 @process_ctrl_num,  @batch_proc_flag,  @debug_level,  @perf_level  IF( @result != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 148, 5 ) + " -- EXIT: " 
 RETURN @result  END       UPDATE #arinppyt_work  SET trx_type = 2113  WHERE void_type IN (2, 4) 
 AND batch_code = @batch_ctrl_num  IF( @@error != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 165, 5 ) + " -- EXIT: " 
 RETURN 34563  END   UPDATE #arnonardet_work  SET #arnonardet_work.trx_type = 2113 
 FROM #arinppyt_work pyt  WHERE pyt.void_type IN (2, 4)  AND pyt.trx_ctrl_num = #arnonardet_work.trx_ctrl_num 
 AND pyt.batch_code = @batch_ctrl_num  IF( @@error != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 180, 5 ) + " -- EXIT: " 
 RETURN 34563  END  UPDATE #arinptax_work  SET #arinptax_work.trx_type = 2113  FROM #arinppyt_work pyt 
 WHERE pyt.void_type IN (2, 4)  AND pyt.trx_ctrl_num = #arinptax_work.trx_ctrl_num 
 AND pyt.batch_code = @batch_ctrl_num  IF( @@error != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 193, 5 ) + " -- EXIT: " 
 RETURN 34563  END   UPDATE #arinppyt_work  SET trx_type = 2112  WHERE void_type = 3 
 AND batch_code = @batch_ctrl_num  IF( @@error != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 206, 5 ) + " -- EXIT: " 
 RETURN 34563  END  UPDATE #arinppdt_work  SET trx_type = pyt.trx_type  FROM #arinppyt_work pyt, #arinppdt_work pdt 
 WHERE pdt.trx_ctrl_num = pyt.trx_ctrl_num  AND pyt.batch_code = @batch_ctrl_num 
 AND pyt.trx_type >= 2112  AND pyt.trx_type <= 2113  IF( @@error != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 220, 5 ) + " -- EXIT: " 
 RETURN 34563  END  END                  EXEC @result = ARCAAdjustDiscWOffs_SP @batch_ctrl_num, 
 @debug_level,  @perf_level  IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 246, 5 ) + " -- EXIT: " 
 RETURN @result  END         EXEC @result = ARPYPostInsertValTables_SP  IF( @result != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 260, 5 ) + " -- EXIT: " 
 RETURN @result  END  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arcapb.sp" + ", line " + STR( 264, 5 ) + " -- EXIT: " 
 IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\arcapb.sp", 265, "Leaving ARCAPostBatch_SP", @PERF_time_last OUTPUT 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[ARCAPostBatch_SP] TO [public]
GO
