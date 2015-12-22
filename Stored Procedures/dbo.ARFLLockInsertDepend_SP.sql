SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


























































  



					  

























































 





































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARFLLockInsertDepend_SP]	@batch_ctrl_num   	varchar( 16 ),
					     	@process_ctrl_num	varchar( 16 ),
						@all_branchcode	smallint,
						@all_cust_flag	smallint,
						@all_price_flag	smallint,
						@date_applied		int,
					      	@debug_level		smallint = 0,
					      	@perf_level	     	smallint = 0 
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result					int,
	@trans_unlocked_flag	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arfllid.cpp", 59, "Entering ARFLLockInsertDepend_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arfllid.cpp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "
	


	EXEC @result = ARFLLockDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@all_branchcode,
							@all_cust_flag,
							@all_price_flag,
							@date_applied,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arfllid.cpp" + ", line " + STR( 76, 5 ) + " -- MSG: " + "ARFLLockDependancies_SP has failed"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arfllid.cpp" + ", line " + STR( 77, 5 ) + " -- MSG: " + "@result = " + STR( @result, 7 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arfllid.cpp" + ", line " + STR( 78, 5 ) + " -- EXIT: "
		RETURN @result
	END

	


	EXEC @result = ARFLInsertDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@all_branchcode,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arfllid.cpp" + ", line " + STR( 92, 5 ) + " -- MSG: " + "ARFLInsertDependancies_SP has failed"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arfllid.cpp" + ", line " + STR( 93, 5 ) + " -- MSG: " + "@result = " + STR( @result, 7 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arfllid.cpp" + ", line " + STR( 94, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arfllid.cpp" + ", line " + STR( 98, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arfllid.cpp", 99, "Leaving ARFLLockInsertDepend_SP", @PERF_time_last OUTPUT
	RETURN 0
END






/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARFLLockInsertDepend_SP] TO [public]
GO
