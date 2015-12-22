SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLLockDependancies_SP]     	@batch_ctrl_num     	varchar( 16 ),
						@process_ctrl_num	varchar( 16 ),
						@all_branchcode	smallint,
						@all_cust_flag	smallint,
						@all_price_flag	smallint,
						@date_applied		int,
					      	@debug_level		smallint = 0,
					      	@perf_level	      	smallint = 0
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result				int,
	@all_trx_marked		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arflld.cpp", 69, "Entering ARFLLockDependencies_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "
	





	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arflld.cpp", 79, "Start inserting dependant transactions into #deplock", @PERF_time_last OUTPUT
	
	







	IF ( @all_cust_flag = 1 ) and ( @all_price_flag = 1 ) and ( @all_branchcode = 1 )
		INSERT	#deplock
		(	
			customer_code,
			doc_ctrl_num, 
			trx_type, 
			lock_status,
			temp_flag 
		)
		SELECT	DISTINCT
			customer_code,
			apply_to_num,
			apply_trx_type,
			0,
			0
		FROM	artrxage
		WHERE	trx_type in (2021, 2031)
	      	AND	(amount+amt_fin_chg+amt_late_chg) > amt_paid
		AND	date_due < @date_applied
		AND     paid_flag = 0 
	


	ELSE 


















































































	 BEGIN

		INSERT	#deplock
		(	
			customer_code,
			doc_ctrl_num, 
			trx_type, 
			lock_status,
			temp_flag 
		)
		SELECT	DISTINCT
			age.customer_code,
			apply_to_num,
			apply_trx_type,
			0,
			0
		FROM	artrxage age, #cust_range cust, #price_range price
		WHERE	trx_type in (2021, 2031)
	      	AND	(amount+amt_fin_chg+amt_late_chg) > amt_paid
		AND	age.customer_code = cust.customer_code
		AND	age.price_code = price.price_code
		AND	date_due < @date_applied
		AND     age.paid_flag = 0  
		AND 	age.org_id IN (SELECT org_id FROM #branch_range)
			
		
	 END 
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 225, 5 ) + " -- MSG: " + "Error inserting into #deplock"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 226, 5 ) + " -- MSG: " + "@@error = " + STR(@@error, 7)
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 227, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF NOT EXISTS(SELECT	customer_code
			FROM	#deplock)
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 234, 5 ) + " -- MSG: " + "No invoice to apply charges to"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 235, 5 ) + " -- EXIT: "
		RETURN	32462
	END
	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "arflld.cpp", 239, "Done inserting dependant transactions into #deplock", @PERF_time_last OUTPUT

   	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Transaction we are going to lock:"
		SELECT	"customer_code, doc_ctrl_num, trx_type, lock_status, temp_flag"

		SELECT	customer_code + " " +
			doc_ctrl_num + " " + 
			STR(trx_type, 6) + " " + 
		      	STR(lock_status, 6) + " " + 
			STR(temp_flag,6 )
		FROM	#deplock
	END
	
	

	
	EXEC @result = ARMarkDependancies_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@all_trx_marked OUTPUT,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 264, 5 ) + " -- MSG: " + "ARMarkDependancies_SP has failed"
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 265, 5 ) + " -- MSG: " + "@result = " + STR( @result, 6 )
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 266, 5 ) + " -- EXIT: "
		RETURN 34563
	END
			
	



	IF( @all_trx_marked = 0 )
	BEGIN
		



		INSERT perror
		(	process_ctrl_num,	batch_code,	module_id,
			err_code,		info1,		info2,
			infoint,    		infofloat, 	flag1,
			trx_ctrl_num,	    	sequence_id,	source_ctrl_num,
			extra
		)
		SELECT	@process_ctrl_num,	@batch_ctrl_num,	2000,
			20900, doc_ctrl_num,	"",
			0,   			0.0,  			1,
			"",			0,			"",
			0
		FROM	#deplock
		WHERE	lock_status != 1

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 297, 5 ) + " -- MSG: " + "Insert into perror failed"
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 298, 5 ) + " -- MSG: " + "perror = " + STR( @@error, 6 )
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 299, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		RETURN 35015
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflld.cpp" + ", line " + STR( 306, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arflld.cpp", 307, "Leaving ARFLLockDependencies_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLLockDependancies_SP] TO [public]
GO
