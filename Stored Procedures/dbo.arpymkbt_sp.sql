SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 10/12/2012 - Issue #1001 - AR - Posting Payments by pay method  
-- v1.1 CB 31/07/2013 - Issue #1315 - When posting settlements some payments are left behind
/*                                                        
               Confidential Information                    
    Limited Distribution of Authorized Persons Only         
    Created 2001 and Protected as Unpublished Work         
          Under the U.S. Copyright Act of 1976              
 Copyright (c) 2001 Epicor Software Corporation, 2001      
                  All Rights Reserved                      
*/                                                  
  
    
CREATE PROCEDURE [dbo].[arpymkbt_sp] @process_ctrl_num varchar(16),  
        @company_code  varchar(8),  
           @debug_level  smallint = 0,  
        @settlement   smallint = 0  
AS  
  
DECLARE  @process_user_id smallint,  
   @process_parent_app smallint,  
   @date_applied  int,  
   @process_user_name varchar(30),  
   @source_batch_code varchar(16),  
   @result  int,  
   @batch_code  varchar(16),  
   @trx_type        smallint,  
   @batch_type      smallint,  
   @batch_proc_flag  smallint,  
   @org_id    varchar(30)  
BEGIN  
   
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 178, 5 ) + ' -- ENTRY: '  
   
  
  
  
 IF ( @@trancount > 0 )  
 BEGIN  
  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 185, 5 ) + ' -- MSG: ' + 'Transaction all ready started.'  
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 186, 5 ) + ' -- EXIT: '  
  RETURN 32544  
 END  
  
 
	-- v1.0 Start - Check if pay method parameters have been set
	DECLARE	@from_pay	varchar(10),
			@end_pay	varchar(10)

	IF EXISTS (SELECT 1 FROM cvo_CR_parameters (NOLOCK) WHERE username = suser_sname())
	BEGIN
		SELECT	@from_pay = from_paymeth,
				@end_pay = end_paymeth 
		FROM	cvo_CR_parameters (NOLOCK) 
		WHERE	username = suser_sname()

		IF EXISTS (SELECT 1 FROM arinppyt (NOLOCK) WHERE (payment_code < @from_pay OR payment_code > @end_pay) 
					AND process_group_num = @process_ctrl_num AND posted_flag = -1)
		BEGIN
			UPDATE	arinppyt
			SET		process_group_num = NULL,
					posted_flag = 0
			WHERE	process_group_num = @process_ctrl_num 
			AND		posted_flag = -1
			AND		(payment_code < @from_pay OR payment_code > @end_pay)
		END
	END
	DELETE cvo_CR_parameters WHERE username = suser_sname() -- v1.1
	-- v1.0 End


 SELECT @batch_proc_flag = batch_proc_flag   
 FROM arco  
  
   
  
  
 if (@settlement = 1)  
 begin  
  select @batch_proc_flag = 0  
 end  
  
   
  
  
 SELECT @process_parent_app = process_parent_app,  
   @process_user_id = process_user_id  
 FROM pcontrol_vw  
 WHERE process_ctrl_num = @process_ctrl_num  
   
 IF ( @process_parent_app IS NULL )  
 BEGIN  
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 214, 5 ) + ' -- EXIT: '  
  RETURN 32545  
 END  
   
   
  
  
 IF NOT EXISTS( SELECT *  
    FROM glcomp_vw  
    WHERE company_code = @company_code )  
 BEGIN  
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 225, 5 ) + ' -- EXIT: '  
  RETURN 32523  
 END  
   
 SET ROWCOUNT 1  
  
 SELECT @trx_type = trx_type  
 FROM arinppyt  
 WHERE process_group_num = @process_ctrl_num  
 AND posted_flag = -1  
  
 SET ROWCOUNT 0  
   
   
  
  
 IF ( ( @batch_proc_flag = 1 ) AND ( @trx_type != 2151 ) )  
 BEGIN  
  UPDATE batchctl  
  SET process_group_num = @process_ctrl_num,  
   posted_flag = -1  
  FROM batchctl a, arinppyt b  
  WHERE a.batch_ctrl_num = b.batch_code  
  AND  b.process_group_num = @process_ctrl_num  
  AND b.posted_flag = -1  
 END  
 ELSE   
 BEGIN  
    
  
  
  
  SELECT DISTINCT date_applied,  
     trx_type,  
     org_id  
  INTO #ar_batches  
  FROM arinppyt  
  WHERE process_group_num = @process_ctrl_num  
  AND ( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = ' ' )  
  AND posted_flag = -1  
    
    
  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 267, 5 ) + ' -- MSG: ' + 'Beginning Transaction'  
  BEGIN TRAN  
  
  WHILE 1=1  
  BEGIN  
     
  
  
  
  
  
  
   SET ROWCOUNT 1  
   SELECT @date_applied = date_applied,  
    @trx_type = trx_type,  
    @org_id = org_id  
   FROM #ar_batches  
   ORDER BY date_applied, trx_type, org_id  
   IF( @@rowcount = 0 )    
   BEGIN  
    SET ROWCOUNT 0  
    break  
   END  
   SET ROWCOUNT 0  
        
   
   if (@trx_type = 2111)  
       SELECT @batch_type = 2050  
   else if (@trx_type IN (2112,2113,2121))  
       SELECT @batch_type = 2060  
   else if (@trx_type = 2151)  
       SELECT @batch_type = 2070  
    
    
   EXEC @result = arnxtbat_sp 2000,  
                     '',  
       @batch_type,  
       @process_user_id,  
       @date_applied,  
       @company_code,  
       @batch_code OUTPUT,  
       0,  
       @org_id   
  
  
  
  
  
  
  
   SET ROWCOUNT 250  
   UPDATE arinppyt  
   SET batch_code = @batch_code  
   WHERE date_applied = @date_applied  
   AND  org_id   = @org_id  
   AND process_group_num = @process_ctrl_num  
   AND ( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = ' ' )  
   AND posted_flag = -1  
   SET ROWCOUNT 0   
  
     
  
  
  
  
  
   IF EXISTS ( SELECT 1  
     FROM arinppyt  
     WHERE date_applied = @date_applied  
     AND  org_id    = @org_id  
     AND process_group_num = @process_ctrl_num  
     AND posted_flag = -1  
     AND ( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = ' ' ))  
   BEGIN   
    SELECT @date_applied = @date_applied  
   END  
   ELSE  
   BEGIN         
    DELETE #ar_batches  
    WHERE date_applied = @date_applied  
    AND  org_id   = @org_id  
   END  
  
     
  
  
  
   UPDATE batchctl  
   SET process_group_num = @process_ctrl_num,  
    posted_flag = -1  
   WHERE batch_ctrl_num = @batch_code  
     
  END  
   
  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 361, 5 ) + ' -- MSG: ' + 'Commiting Transaction'  
  COMMIT TRAN  
  
  DROP TABLE #ar_batches  
 END  
  
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 367, 5 ) + ' -- EXIT: '  
 RETURN 0  
   
 rollback_tran:  
 IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 371, 5 ) + ' -- MSG: ' + 'Rolling Back transaction'  
 ROLLBACK TRAN  
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arpymkbt.cpp' + ', line ' + STR( 373, 5 ) + ' -- EXIT: '  
 RETURN 32502  
END  
/**/                                                
GO
GRANT EXECUTE ON  [dbo].[arpymkbt_sp] TO [public]
GO
