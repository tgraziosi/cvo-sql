SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMModifyPersistant_SP] @batch_ctrl_num varchar( 16 ),
 @debug_level smallint = 0,
 @perf_level smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE @result int,
 @err_msg varchar(100)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmmp.sp", 79, "ARCMModfyPersistant_SP", @PERF_time_last OUTPUT

BEGIN
 
 EXEC @result = aractcus_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 90, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = aractprc_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 102, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = aractshp_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 114, 5 ) + " -- EXIT: "
 RETURN @result
 END
 
 EXEC @result = aractslp_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = aractter_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arinpcdt_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 149, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arinpchg_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 161, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arinpcom_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 173, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arinptax_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 185, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arsumcus_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 197, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arsumprc_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 209, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arsumshp_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 221, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arsumslp_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 233, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = arsumter_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 245, 5 ) + " -- EXIT: "
 RETURN @result
 END


 
 EXEC @result = artrx_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 258, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = artrxage_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 270, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = artrxcdt_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 282, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = artrxcom_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 294, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = artrxtax_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 306, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = artrxxtr_sp @batch_ctrl_num,
 @debug_level,
 @perf_level
 IF( @result != 0 OR @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 318, 5 ) + " -- EXIT: "
 RETURN @result
 END

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmmp.sp" + ", line " + STR( 322, 5 ) + " -- EXIT: "
 RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCMModifyPersistant_SP] TO [public]
GO
