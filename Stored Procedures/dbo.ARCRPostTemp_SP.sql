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































































  



					  

























































 





















































































































































































































































































































CREATE PROC [dbo].[ARCRPostTemp_SP]	@batch_ctrl_num	varchar( 16 ),
				@cm_flag		smallint,
				@process_ctrl_num	varchar( 16 ),
				@process_user_id	smallint,
				@journal_type		varchar( 8 ),
				@company_code		varchar( 8 ),
				@home_cur_code	varchar( 8 ),
				@debug_level		smallint = 0,
				@perf_level		smallint = 0	
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
      	@result	int


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 60, 5 ) + ' -- ENTRY: '
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcrpt.cpp', 61, 'Entering ARCRPostTemp_SP', @PERF_time_last OUTPUT
	
	



	
CREATE TABLE #arcrtemp
(
	trx_ctrl_num            varchar(16),
	trx_type                        smallint,
	journal_ctrl_num        varchar(16),
)

	
	





	
CREATE TABLE #ardepnum
(
	payment_code			varchar(8),
	cash_acct_code		varchar(32),
	nat_cur_code			varchar(8),
	date_applied			int,
	deposit_num			varchar(16) NULL,
	deposit_amount		float,
	org_id			varchar(30) NULL

)

	
	






	EXEC @result = ARCRGetDepositNum_SP  @batch_ctrl_num,
						  @debug_level,
						  @perf_level
		
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 90, 5 ) + ' -- EXIT: '
		RETURN @result
	END



	

	
	EXEC @result = ARCRProcPaymentDet_SP 		@batch_ctrl_num,
								@debug_level,
								@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 105, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	


	EXEC @result = ARCRCreateAgingRecs_SP 	@batch_ctrl_num,
						    	@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 118, 5 ) + ' -- EXIT: '
		RETURN @result
	END
		
	

	
	EXEC @result = ARCRCreateDependantTrans_SP  @batch_ctrl_num,
								@debug_level,
								@perf_level
	
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 131, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	



	
	EXEC @result = ARCRUpdateDependTrans_SP 	@batch_ctrl_num,
							@process_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 147, 5 ) + ' -- EXIT: '
		RETURN @result
	END
	
	DROP TABLE #ardepnum
	


	EXEC @result = ARCRUpdateActivitySummary_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 160, 5 ) + ' -- EXIT: '
		RETURN @result
	END
	
	


	EXEC @result = ARCRMoveUnpostedRecords_SP	 @batch_ctrl_num,
							 @debug_level,
							 @perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 173, 5 ) + ' -- EXIT: '
		RETURN @result
	END
	
	DROP TABLE #arcrtemp

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcrpt.cpp', 179, 'Leaving ARCRPostTemp_SP', @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcrpt.cpp' + ', line ' + STR( 180, 5 ) + ' -- EXIT: '
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCRPostTemp_SP] TO [public]
GO
