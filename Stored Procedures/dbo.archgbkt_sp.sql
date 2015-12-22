SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

  CREATE PROC [dbo].[archgbkt_sp] @batch_ctrl_num varchar( 16 ), @debug_level smallint = 0,  @perf_level smallint = 0 WITH RECOMPILE AS    DECLARE 
   @PERF_time_last datetime SELECT @PERF_time_last = GETDATE()    

  DECLARE  @status int 
  BEGIN  
	SELECT @status = 0  
	IF ( @debug_level > 1 ) SELECT "tmp/archgbkt.sp" + ", line " + STR( 43, 5 ) + " -- ENTRY: " 
 	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/archgbkt.sp", 45, "entry archgbkt_sp", @PERF_time_last OUTPUT 
        
	DELETE archgbk  
	FROM #arinppyt_work a, archgbk b  
	WHERE a.trx_ctrl_num = b.trx_ctrl_num 
	AND	db_action = 4

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/archgbkt.sp", 126, "exit archgbkt_sp", @PERF_time_last OUTPUT 
 	RETURN @status 
  END 
GO
GRANT EXECUTE ON  [dbo].[archgbkt_sp] TO [public]
GO
