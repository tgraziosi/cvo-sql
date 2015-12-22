SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

                                                                                 
             CREATE PROCEDURE [dbo].[aprecov_sp] @process_group_num varchar(16),  @batch_code varchar(16), 
 @debug smallint AS DECLARE @batch_proc_flag smallint,  @process_type smallint,  @trx_ctrl_num varchar(16), 
 @result smallint SELECT @process_type = process_type FROM pcontrol_vw WHERE process_ctrl_num = @process_group_num 
   SELECT @batch_proc_flag = batch_proc_flag FROM apco    IF @process_type = 4091 
 BEGIN     IF (@batch_proc_flag = 0)  UPDATE apinpchg  SET posted_flag = 0,  process_group_num = '', 
 batch_code = ''  WHERE process_group_num = @process_group_num  AND (batch_code = @batch_code 
 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))  ELSE  UPDATE apinpchg 
 SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
         IF (@batch_proc_flag = 0)  UPDATE apinppyt  SET posted_flag = 0,  process_group_num = '', 
 batch_code = ''  WHERE process_group_num = @process_group_num  AND (batch_code = @batch_code 
 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))  ELSE  UPDATE apinppyt 
 SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
     UPDATE apvohdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
 END    ELSE IF @process_type = 4021  BEGIN     IF (@batch_proc_flag = 0)  UPDATE apinpchg 
 SET posted_flag = 0,  process_group_num = '',  batch_code = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
 ELSE  UPDATE apinpchg  SET posted_flag = 0,  process_group_num = '',  batch_code = '' 
 WHERE process_group_num = @process_group_num  AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
     UPDATE apvohdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
 END    ELSE IF @process_type = 4092  BEGIN     IF (@batch_proc_flag = 0)  UPDATE apinpchg 
 SET posted_flag = 0,  process_group_num = '',  batch_code = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
 ELSE  UPDATE apinpchg  SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
     IF (@batch_proc_flag = 0)  UPDATE apinppyt  SET posted_flag = 0,  process_group_num = '', 
 batch_code = ''  WHERE process_group_num = @process_group_num  AND (batch_code = @batch_code 
 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))  ELSE  UPDATE apinppyt 
 SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
     UPDATE apvohdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
     UPDATE appyhdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
 END    ELSE IF @process_type = 4111  BEGIN      IF (@batch_proc_flag = 0)  UPDATE apinppyt 
 SET posted_flag = 0,  process_group_num = '',  batch_code = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
 ELSE  UPDATE apinppyt  SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
     UPDATE apvohdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
     UPDATE appyhdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
 END    ELSE IF @process_type = 4112  BEGIN      IF (@batch_proc_flag = 0)  UPDATE apinppyt 
 SET posted_flag = 0,  process_group_num = '',  batch_code = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
 ELSE  UPDATE apinppyt  SET posted_flag = 0,  process_group_num = '',  batch_code = '' 
 WHERE process_group_num = @process_group_num  AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
     UPDATE apvohdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
     UPDATE appyhdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
 END    ELSE IF @process_type IN (4999, 4998)  BEGIN      UPDATE apvohdr  SET state_flag = 1, 
 process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num      IF @process_type = 4998 
 UPDATE appyhdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
 END    ELSE IF @process_type = 4997  BEGIN          IF (@batch_proc_flag = 0)  UPDATE apinppyt 
 SET posted_flag = 0,  process_group_num = '',  batch_code = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
 ELSE  UPDATE apinppyt  SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
     UPDATE apvohdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
     SELECT @trx_ctrl_num = trx_ctrl_num  FROM apinpchg  WHERE process_group_num = @process_group_num 
 AND (batch_code = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
 IF @trx_ctrl_num IS NOT NULL  EXEC @result = aprecov_sp @trx_ctrl_num, @debug  END 
   ELSE IF @process_type IN (4996, 4995, 4994, 4993)  BEGIN      UPDATE apvchdr  SET state_flag = 1, 
 process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num      UPDATE apchkstb 
 SET posted_flag = 0  FROM apchkstb,apinppyt  WHERE apchkstb.payment_num = apinppyt.trx_ctrl_num 
 AND apinppyt.process_group_num = @process_group_num      UPDATE apexpdst  SET posted_flag = 0 
 FROM apexpdst,apinppyt  WHERE apexpdst.payment_num = apinppyt.trx_ctrl_num  AND apinppyt.process_group_num = @process_group_num 
     UPDATE apinppyt  SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
 END    ELSE IF @process_type = 4116 BEGIN      UPDATE apinpstl  SET state_flag = 0, 
 process_group_num = ''  WHERE process_group_num = @process_group_num      UPDATE apinppyt 
 SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
     UPDATE apvohdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
     UPDATE apdmhdr  SET state_flag = 1,  process_ctrl_num = ''  WHERE process_ctrl_num = @process_group_num 
END    IF @process_type NOT IN (4999, 4998, 4996,  4995, 4994, 4993)  BEGIN  IF (@batch_proc_flag = 0) 
 UPDATE batchctl  SET void_flag = 1,  posted_flag = 0  WHERE process_group_num = @process_group_num 
 AND (batch_ctrl_num = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
 AND posted_flag = -1  AND batch_type BETWEEN 4000 AND 5000  ELSE  BEGIN  UPDATE batchctl 
 SET posted_flag = 0,  process_group_num = ''  WHERE process_group_num = @process_group_num 
 AND (batch_ctrl_num = @batch_code  OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " )) 
 AND posted_flag = -1  AND batch_type IN (4010, 4030, 4040)  UPDATE batchctl  SET void_flag = 1, 
 posted_flag = 0  WHERE process_group_num = @process_group_num  AND (batch_ctrl_num = @batch_code 
 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))  AND posted_flag = -1 
 AND batch_type IN (4050, 4060)  END  END RETURN 0 

 /**/
GO
GRANT EXECUTE ON  [dbo].[aprecov_sp] TO [public]
GO
