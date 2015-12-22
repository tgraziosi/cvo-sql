SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apungen_sp]  @user_id smallint AS DECLARE @max_gen_id int, @batch_proc_flag smallint, @batch_ctrl_num varchar(16), @record_count int 
SELECT @batch_proc_flag = batch_proc_flag FROM apco     SELECT @record_count = 0 
DECLARE Generated_Payments CURSOR FOR  SELECT gen_id  FROM #genpayments  WHERE selected = 1 
 ORDER BY gen_id OPEN Generated_Payments FETCH NEXT FROM Generated_Payments INTO @max_gen_id 
WHILE @@FETCH_STATUS = 0 BEGIN  BEGIN TRANSACTION  IF @max_gen_id IS NULL  BEGIN 
 COMMIT TRANSACTION  SELECT 0   RETURN  END  SELECT @record_count = @record_count + 1 
 IF (@batch_proc_flag = 1)  BEGIN  SET ROWCOUNT 1  SELECT @batch_ctrl_num = batch_code 
 FROM apinppyt  WHERE gen_id = @max_gen_id  SET ROWCOUNT 0  END      DELETE FROM apaprtrx 
 WHERE apaprtrx.trx_ctrl_num  IN ( SELECT trx_ctrl_num FROM apinppyt  WHERE apinppyt.gen_id = @max_gen_id 
 AND apinppyt.user_id = @user_id  AND posted_flag = 0  AND printed_flag != 1  AND trx_type = 4111 ) 
     DELETE FROM apinppdt  WHERE apinppdt.trx_ctrl_num  IN ( SELECT trx_ctrl_num FROM apinppyt 
 WHERE apinppyt.gen_id = @max_gen_id  AND apinppyt.user_id = @user_id  AND posted_flag = 0 
 AND printed_flag != 1  AND trx_type = 4111 )      DELETE FROM apinppyt  WHERE gen_id = @max_gen_id 
 AND user_id = @user_id  AND posted_flag = 0  AND trx_type = 4111  AND printed_flag != 1 
      IF (@batch_proc_flag = 1)  BEGIN  DELETE batchctl  WHERE batch_ctrl_num = @batch_ctrl_num 
 AND NOT EXISTS (SELECT * FROM apinppyt  WHERE batch_code = @batch_ctrl_num)     
 IF (@@rowcount = 0)  BEGIN  UPDATE batchctl  SET actual_number = (SELECT COUNT(*) FROM apinppyt 
 WHERE batch_code = @batch_ctrl_num),  actual_total = (SELECT SUM(amt_payment) FROM apinppyt 
 WHERE batch_code = @batch_ctrl_num),  number_held = (SELECT SUM(hold_flag) FROM apinppyt 
 WHERE batch_code = @batch_ctrl_num)  FROM batchctl  WHERE batch_ctrl_num = @batch_ctrl_num 
 END  END  COMMIT TRANSACTION  FETCH NEXT FROM Generated_Payments INTO @max_gen_id 
END CLOSE Generated_Payments DEALLOCATE Generated_Payments SELECT @record_count  
GO
GRANT EXECUTE ON  [dbo].[apungen_sp] TO [public]
GO
