SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLApplyCharges_SP]	@batch_ctrl_num	varchar( 16 ),
					@charge_option	smallint, 
					@date_applied		int,
					@home_currency	varchar( 8 ),
					@oper_currency	varchar( 8 ),
					@user_id		int,
					@debug_level		smallint = 0,
					@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
 	@result	int


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflac.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflac.sp", 65, "Entering ARFLApplyCharges_SP", @PERF_time_last OUTPUT
	
	IF (@debug_level > 0 )
		SELECT "date_applied = " + STR(@date_applied, 8)
		
	
	INSERT	#cust_info(	customer_code, customer_name, fin_chg_code, 
	 			late_chg_type, nat_cur_code, rate_type_home, 
				rate_type_oper, posting_code, overdue_amt, 
				min_date_due 
	 		)
	SELECT	DISTINCT cust.customer_code, cust.customer_name, cust.fin_chg_code, 
			 cust.late_chg_type, cust.nat_cur_code, cust.rate_type_home, 
			 cust.rate_type_oper, cust.posting_code, 0.0, 0
 	FROM	#artrx_work trx, arcust cust
	WHERE	cust.customer_code = trx.customer_code
		
 	IF( @@error != 0 )
 	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflac.sp" + ", line " + STR( 89, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF EXISTS (	SELECT customer_code
			FROM	#cust_info
			WHERE	late_chg_type = 2
		 )
	BEGIN
		
		SELECT	cust.customer_code, SUM(inv.amt_tot_chg - inv.amt_paid_to_date) overdue_amt,
			MIN(inv.date_due) min_date_due
		INTO	#overdue_amt
		FROM	#artrx_work inv, #cust_info	cust
		WHERE	inv.customer_code = cust.customer_code
		AND	inv.doc_ctrl_num = inv.apply_to_num
		AND	inv.trx_type = inv.apply_trx_type
		AND	inv.trx_type <= 2031
		AND	((inv.amt_tot_chg) > (inv.amt_paid_to_date) + 0.0000001)
		AND	inv.date_due < @date_applied
		AND	cust.late_chg_type = 2
		GROUP BY cust.customer_code
		
		UPDATE	#cust_info
		SET	overdue_amt = amt.overdue_amt,
			min_date_due = amt.min_date_due
		FROM	#overdue_amt amt
		WHERE	amt.customer_code = #cust_info.customer_code
		AND	late_chg_type = 2
		
			
		UPDATE	#cust_info
		SET	overdue_amt = 0.0
		FROM	#cust_info cust, artrxage late
		WHERE	cust.customer_code = late.customer_code
		AND	late.trx_type = 2071
		AND	late.date_applied >= @date_applied
		AND	cust.late_chg_type = 2
		
		IF( @@error != 0 )
	 	BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflac.sp" + ", line " + STR( 134, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	
	END
		
	IF ( @debug_level > 0 )
	BEGIN
	 	SELECT "dumping #cust_info..."
	 	SELECT	"customer_code = " + customer_code +
	 		"late_chg_type = " + STR(late_chg_type, 2 )
	 	FROM	#cust_info
 	END

	
	IF ( SIGN(@charge_option) != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflac.sp" + ", line " + STR( 153, 5 ) + " -- MSG: " + "Applying fin charges..."

		EXEC @result = ARFLApplyFINcharges_SP 	@batch_ctrl_num,
								@date_applied,
								@home_currency,
								@oper_currency,
								@debug_level,
								@perf_level

		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflac.sp" + ", line " + STR( 164, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
		
	IF ( SIGN(@charge_option - 1) != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflac.sp" + ", line " + STR( 174, 5 ) + " -- MSG: " + "Applying late charges..."
		EXEC @result = ARFLApplyLTEcharges_SP 	@batch_ctrl_num,
								@date_applied,
								@home_currency,
								@oper_currency,
								@user_id,
								@debug_level,
								@perf_level

		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflac.sp" + ", line " + STR( 185, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	DROP TABLE #prev_charges

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arflac.sp", 192, "Leaving ARFLApplyCharges_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arflac.sp" + ", line " + STR( 193, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARFLApplyCharges_SP] TO [public]
GO
