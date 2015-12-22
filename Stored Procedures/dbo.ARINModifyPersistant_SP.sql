SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arinmp.SPv - e7.2.2 : 1.12
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARINModifyPersistant_SP]			@batch_ctrl_num		varchar( 16 ),
											@debug_level		smallint = 0,
											@perf_level			smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinmp.sp", 95, "ARINModifyPersistant_SP", @PERF_time_last OUTPUT

BEGIN
	
	EXEC @result = aractcus_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractprc_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 118, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractshp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 130, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	EXEC @result = aractslp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = aractter_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 153, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arcycle_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 165, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinpage_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 177, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinpcdt_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 189, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinpchg_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 201, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinpcom_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 213, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinprev_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 225, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinptax_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 237, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arinptmp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 249, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumcus_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 261, 5 ) + " -- EXIT: "
		RETURN @result
	END
 
	
	EXEC @result = arsumprc_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 273, 5 ) + " -- EXIT: "
		RETURN @result
	END
 
	
	EXEC @result = arsumshp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 285, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumslp_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 297, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = arsumter_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 309, 5 ) + " -- EXIT: "
		RETURN @result
	END


	
	EXEC @result = artrx_sp	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 322, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = artrxage_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 334, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = artrxcdt_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 346, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = artrxcom_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 358, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = artrxrev_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 370, 5 ) + " -- EXIT: "
		RETURN @result
	END


	
	EXEC @result = artrxtax_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 383, 5 ) + " -- EXIT: "
		RETURN @result
	END


	
	EXEC @result = artrxxtr_sp	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 OR @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 396, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinmp.sp" + ", line " + STR( 400, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINModifyPersistant_SP] TO [public]
GO
