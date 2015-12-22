SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/


                                                                            
                                                                                CREATE PROC [dbo].[ARModifyPersistant_SP] @batch_ctrl_num varchar( 16 ), 
 @debug_level smallint = 0,  @perf_level smallint = 0 AS    DECLARE  @PERF_time_last datetime 
SELECT @PERF_time_last = GETDATE()    DECLARE  @result int,  @err_msg varchar(100) 
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\armp.sp", 70, "ARModifyPersistant_SP", @PERF_time_last OUTPUT 
BEGIN  EXEC @result = aractcus_sp @batch_ctrl_num,  @debug_level,  @perf_level  IF( @result != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 78, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = aractprc_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 87, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = aractshp_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 96, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = aractslp_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 105, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = aractter_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 114, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arinpcdt_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 123, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arinpchg_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 132, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arinppdt_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arinppyt_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 150, 5 ) + " -- EXIT: " 
 RETURN 34563  END   EXEC @result = arnonardet_sp @batch_ctrl_num,  @debug_level, 
 @perf_level  IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 162, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arinptax_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 171, 5 ) + " -- EXIT: " 
 RETURN 34563  END   EXEC @result = arsumcus_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 185, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arsumprc_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 194, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arsumshp_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 203, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arsumslp_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 212, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = arsumter_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 221, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = artrx_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 230, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = artrxage_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 239, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = artrxpdt_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 248, 5 ) + " -- EXIT: " 
 RETURN 34563  END   EXEC @result = artrxtax_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 258, 5 ) + " -- EXIT: " 
 RETURN 34563  END  EXEC @result = artrxndet_sp @batch_ctrl_num,  @debug_level,  @perf_level 
 IF( @result != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 267, 5 ) + " -- EXIT: " 
 RETURN 34563  END   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\armp.sp" + ", line " + STR( 274, 5 ) + " -- EXIT: " 




	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN
			/* Begin mod: CB0001 - Added call to archgbkt_sp for archgbk table */  
		EXEC @result = archgbkt_sp 	@batch_ctrl_num,  
					@debug_level,  
					@perf_level 

	 	IF( @result != 0 )  
		BEGIN  
			IF ( @debug_level > 1 ) SELECT "tmp/armp.sp" + ", line " + STR( 223, 5 ) + " -- EXIT: " 
	 		RETURN 34563  
		END  
			/* End mod: CB0001 */
	END




 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[ARModifyPersistant_SP] TO [public]
GO
