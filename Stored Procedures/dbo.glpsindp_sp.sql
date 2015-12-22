SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[glpsindp_sp] @process_ctrl_num varchar(16),  @company_code varchar(8), 
 @debug_level smallint = 0 AS BEGIN  DECLARE @result int,  @batch_mode_on smallint, 
 @batch_code varchar(16),  @work_time datetime  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\glpsindp.sp" + ", line " + STR( 107, 5 ) + " -- ENTRY: " 
 SELECT @work_time = getdate()      SELECT @batch_mode_on = batch_proc_flag  FROM glco 
      IF ( @@trancount > 0 )  BEGIN  return 1052  END       IF ( @batch_mode_on = 1 ) 
 BEGIN  WHILE ( 1 = 1 )  BEGIN      SELECT @batch_code = NULL  SELECT @batch_code = MIN( batch_ctrl_num ) 
 FROM batchctl  WHERE posted_flag = -1  AND batch_type = 6010  AND process_group_num = @process_ctrl_num 
 AND company_code = @company_code  IF ( @batch_code IS NULL )  break  BEGIN TRAN 
 IF ( @debug_level > 1 )    BEGIN  SELECT journal_ctrl_num+" "+batch_code  FROM batchctl b, gltrx h 
 WHERE b.batch_ctrl_num = @batch_code  AND b.batch_ctrl_num = h.batch_code  END  UPDATE gltrx 
 SET posted_flag = 0  FROM batchctl b, gltrx h  WHERE b.batch_ctrl_num = @batch_code 
 AND b.batch_ctrl_num = h.batch_code  AND h.posted_flag = -1  IF ( @@error != 0 ) 
 BEGIN  SELECT @result = 1039  goto rollback_trx  END  EXEC @result = batupdst_sp @batch_code, 
 0  IF ( @result != 0 )  BEGIN  SELECT @result = 1039  goto rollback_trx  END  COMMIT TRAN 
 END  END        ELSE  BEGIN  INSERT #gltrxjcn  SELECT journal_ctrl_num  FROM gltrx 
 WHERE process_group_num = @process_ctrl_num  AND company_code = @company_code  AND posted_flag = -1 
 UPDATE gltrx  SET posted_flag = 0,  batch_code = " "  FROM gltrx t, #gltrxjcn j 
 WHERE t.journal_ctrl_num = j.journal_ctrl_num  IF ( @@error != 0 )  BEGIN  SELECT @result = 1039 
 TRUNCATE TABLE #gltrxjcn  goto rollback_trx  END  TRUNCATE TABLE #gltrxjcn  END 
 IF ( @debug_level > 2 )  BEGIN  SELECT "Transaction group posted INDIRECT"  SELECT "Execution Time: " + 
 convert( char(10), datediff(ms, @work_time, getdate() )) + "ms"  END  IF ( @debug_level > 1 ) SELECT "tmp\\glpsindp.sp" + ", line " + STR( 220, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Exiting" 
 RETURN 0  rollback_trx:  ROLLBACK TRAN  IF ( @debug_level > 1 ) SELECT "tmp\\glpsindp.sp" + ", line " + STR( 228, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Exiting - ERROR" 
 return @result END 
GO
GRANT EXECUTE ON  [dbo].[glpsindp_sp] TO [public]
GO
