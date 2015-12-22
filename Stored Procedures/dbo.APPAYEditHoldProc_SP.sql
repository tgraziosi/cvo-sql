SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[APPAYEditHoldProc_SP] @put_on_hold smallint,  @debug_level smallint, 
 @process_ctrl_num varchar(16) AS DECLARE @batch_mode smallint BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\appayehp.sp" + ", line " + STR( 25, 5 ) + " -- ENTRY: " 
 CREATE TABLE #batchcodes  (  batch_code varchar(8)  )  IF (@put_on_hold = 1)  BEGIN 
 SELECT @batch_mode = batch_proc_flag FROM apco        IF @batch_mode = 1  BEGIN 
 INSERT #batchcodes(batch_code)  SELECT DISTINCT a.batch_code  FROM apinppyt a, perror b, apedterr c 
 WHERE a.trx_ctrl_num = b.trx_ctrl_num  AND a.trx_type = 4111  AND b.err_code = c.err_code 
 AND c.err_type = 0  AND b.process_ctrl_num = @process_ctrl_num  END  BEGIN TRANSACTION 
        UPDATE apinppyt  SET hold_flag = 1  FROM apinppyt a, perror b, apedterr c 
 WHERE a.trx_ctrl_num = b.trx_ctrl_num  AND a.trx_type = 4111  AND b.err_code = c.err_code 
 AND c.err_type = 0  AND b.process_ctrl_num = @process_ctrl_num  UPDATE apinpstl 
 SET hold_flag = 1  FROM apinpstl e,apinppyt a, perror b, apedterr c  WHERE a.trx_ctrl_num = b.trx_ctrl_num 
 AND a.trx_type = 4111  AND b.err_code = c.err_code  AND c.err_type = 0  AND b.process_ctrl_num = @process_ctrl_num 
 AND e.settlement_ctrl_num = a.settlement_ctrl_num                         IF @batch_mode = 1 
 BEGIN  UPDATE batchctl  SET hold_flag = 1,  number_held =(SELECT SUM(hold_flag) 
 FROM apinppyt  WHERE apinppyt.batch_code = batchctl.batch_ctrl_num)  FROM batchctl, #batchcodes b 
 WHERE batchctl.batch_ctrl_num = b.batch_code  END  COMMIT TRANSACTION  END  DROP TABLE #batchcodes 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\appayehp.sp" + ", line " + STR( 118, 5 ) + " -- EXIT: " 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[APPAYEditHoldProc_SP] TO [public]
GO
