SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcmuts.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCMUpdateTempStatistics_SP] @batch_ctrl_num varchar( 16 ),
 @debug_level smallint = 0,
 @perf_level smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
 @result int
BEGIN
 IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmuts.sp", 42, "ARCMUpdateTempStatistics_SP", @PERF_time_last OUTPUT

 UPDATE STATISTICS #aractcus_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 47, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #aractprc_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 54, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #aractshp_work 
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 61, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #aractslp_work 
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 68, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #aractter_work 
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 75, 5 ) + " -- EXIT: "
 RETURN 34563
 END

 UPDATE STATISTICS #arinpcdt_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 82, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #arinpchg_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 89, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #arinpcom_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 96, 5 ) + " -- EXIT: "
 RETURN 34563
 END

 UPDATE STATISTICS #arinptax_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 103, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #arsumcus_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 110, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #arsumprc_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #arsumshp_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 124, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #arsumslp_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 131, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #arsumter_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 138, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #artrx_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 145, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #artrxage_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 152, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #artrxcdt_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 159, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #artrxcom_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 166, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #artrxtax_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 173, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 UPDATE STATISTICS #artrxxtr_work
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 182, 5 ) + " -- EXIT: "
 RETURN 34563
 END
 
 IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmuts.sp", 186, "Leaving ARCMUpdateTempStatistics_SP", @PERF_time_last OUTPUT
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmuts.sp" + ", line " + STR( 187, 5 ) + " -- EXIT: "
 RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCMUpdateTempStatistics_SP] TO [public]
GO
