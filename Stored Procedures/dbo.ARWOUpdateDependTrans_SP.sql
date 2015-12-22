SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOUpdateDependTrans_SP]	@batch_ctrl_num	varchar(16),
						@process_ctrl_num	varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result		int,
	@process_group_num	varchar(16),
	@x_user_id		smallint,
	@x_sys_date		int, 
	@batch_type		smallint,
	@period_end 	int,
	@amt_tot_chg	float,	
	@amt_to_date	float,	
	@paid_value		int 	



IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arwoudt.cpp", 72, "Entering ARWOUpdateDependTrans", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoudt.cpp" + ", line " + STR( 75, 5 ) + " -- ENTRY: "
	
	







	


	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_group_num OUTPUT,
					@x_user_id OUTPUT,
					@x_sys_date OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoudt.cpp" + ", line " + STR( 97, 5 ) + " -- EXIT: "
		RETURN 35011
	END
  

	






	
			SELECT @amt_tot_chg = amt_tot_chg
			FROM #arinppdt_work
			
			SELECT @amt_to_date = amt_paid_to_date + inv_amt_applied
			FROM #arinppdt_work
			
			if ( @amt_tot_chg <= @amt_to_date )  
				SELECT @paid_value = 1  
			else  
				SELECT @paid_value = 0 
	

	UPDATE	#artrx_work
	SET	date_paid = a.date_applied,
		paid_flag = @paid_value,												
		amt_paid_to_date = #artrx_work.amt_paid_to_date + b.inv_amt_applied,	
		db_action = #artrx_work.db_action | 1
	FROM	#arinppyt_work a, #arinppdt_work b
	WHERE	a.trx_ctrl_num = b.trx_ctrl_num
	AND	a.trx_type = b.trx_type
	AND	a.batch_code = @batch_ctrl_num
	AND	b.apply_to_num = #artrx_work.doc_ctrl_num
	AND	b.apply_trx_type = #artrx_work.trx_type
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoudt.cpp" + ", line " + STR( 136, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	











	UPDATE	#artrxage_work
	SET	amt_paid = 	#artrxage_work.amount + 
				#artrxage_work.amt_fin_chg +
				#artrxage_work.amt_late_chg ,
		amount = #artrxage_work.true_amount,
		paid_flag = @paid_value,
		date_paid = a.date_paid,
		db_action = #artrxage_work.db_action | 1
	FROM	#artrx_work a
	WHERE	a.doc_ctrl_num = #artrxage_work.apply_to_num
	AND	a.trx_type = #artrxage_work.apply_trx_type
	AND	#artrxage_work.trx_type IN (2021, 2031, 2071)
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoudt.cpp" + ", line " + STR( 170, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF (@debug_level > 2)
	BEGIN
		SELECT "#######################################"
		SELECT 	"artrxage_work"
		SELECT 	" trx_ctrl_num = " + trx_ctrl_num +
				" doc_ctrl_num = " + doc_ctrl_num +
				" apply_to_num = " + apply_to_num +
				" trx_type = " + STR(trx_type,6) +
				" customer_code = " + customer_code	+
				" amount = " + STR(amount,10,2)
		FROM #artrxage_work
		SELECT "#######################################"

	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwoudt.cpp" + ", line " + STR( 189, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arwoudt.cpp", 190, "Leaving ARWOUpdateDependantTrans_SP", @PERF_time_last OUTPUT
    RETURN 0 

END   

GO
GRANT EXECUTE ON  [dbo].[ARWOUpdateDependTrans_SP] TO [public]
GO
