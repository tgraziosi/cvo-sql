SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARFLPostBatch_SP]		@all_branchcode	smallint,
					@all_cust_flag	smallint,
					@all_price_flag	smallint,
					@charge_option	smallint,
					@date_applied		int,
					@process_ctrl_num	varchar(16),
					@process_user_id	smallint,
					@debug_level        	smallint = 0
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result		int,
	@journal_type		varchar( 8 ),
	@company_code		varchar( 8 ),
	@home_currency	varchar( 8 ),
	@oper_currency	varchar( 8 ),
	@validation_status	int,
	@batch_ctrl_num	varchar( 16 ),
       @perf_level         	smallint,
       @status		int    

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arflpb.cpp", 87, "Entering ARFLPostBatch_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 90, 5 ) + " -- ENTRY: "
	
	SELECT @perf_level = 0
			
	


	
CREATE TABLE #cust_info
(
	customer_code		varchar(8),
	customer_name		varchar(40),
	fin_chg_code		varchar(8),
	late_chg_type		smallint,
	nat_cur_code		varchar(8),
	rate_type_home	varchar(8),
	rate_type_oper	varchar(8),
	posting_code		varchar(8),
	overdue_amt		float,
	min_date_due		int
)



	
CREATE TABLE #prev_charges
(	customer_code		varchar(8), 
	trx_type		int, 
	date_applied		int,
	apply_to_num		varchar(16)	NULL, 
	apply_trx_type	int		NULL, 
	sub_apply_num		varchar(16)	NULL,
	sub_apply_type	int		NULL, 
	date_aging		int		NULL
)

		
	


	SELECT @batch_ctrl_num = batch_ctrl_num
	FROM	batchctl
	WHERE	process_group_num = @process_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 109, 5 ) + " -- MSG: " + "Can't get batch_ctrl_num"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 110, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	INSERT pbatch (	process_ctrl_num,	batch_ctrl_num,
				start_number,		start_total,
				end_number,		end_total,
				start_time,		end_time,
				flag    
			)
	VALUES        (
				@process_ctrl_num, 	@batch_ctrl_num,
				0,		       0,
				0,		      	0,
				getdate(),	     	NULL,
				0
			)

	


	SELECT	@journal_type = journal_type
	FROM	glappid
	WHERE	app_id = 2000
	IF( @@error != 0 OR @journal_type IS NULL )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 136, 5 ) + " -- MSG: " + "journal_type not found in glappid"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	SELECT	@company_code = company_code,
		@home_currency = home_currency,
		@oper_currency = oper_currency
	FROM	glco
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 150, 5 ) + " -- MSG: " + "Company code not found in glcomp_vw"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 151, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	




	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 160, 5 ) + " -- MSG: " + "Calling ARFLLockInsertDepend_SP"
	EXEC @result = ARFLLockInsertDepend_SP	@batch_ctrl_num,
							@process_ctrl_num,
							@all_branchcode,
							@all_cust_flag,
							@all_price_flag,
							@date_applied,
							@debug_level,
							@perf_level
							
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 172, 5 ) + " -- EXIT: "
        	RETURN @result
	END

	


	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 179, 5 ) + " -- MSG: " + "Calling ARFLProcess_SP"
	EXEC @result = ARFLProcess_SP	@batch_ctrl_num, 
						@process_ctrl_num,
						@process_user_id,
						@journal_type,
						@company_code,
						@home_currency,
						@oper_currency,
						@charge_option,
						@date_applied,
                                    	@debug_level, 
                                    	@perf_level 
    	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 193, 5 ) + " -- EXIT: "
       	RETURN @result
	END
	
	UPDATE pbatch
	SET 	start_number = (	SELECT COUNT(*) 
					FROM 	#artrx_work
					WHERE	trx_type >= 2061
					AND	trx_type <= 2071
				  ),
		start_total = (	SELECT ISNULL(SUM(amt_net),0.0) 
					FROM 	#artrx_work
					WHERE	trx_type >= 2061
					AND	trx_type >= 2071
				),
		flag = 1
	WHERE 	batch_ctrl_num = @batch_ctrl_num
	AND 	process_ctrl_num = @process_ctrl_num
   	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 213, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	UPDATE	#artrx_work
	SET	posted_flag = 1,
		process_group_num = ' ',
		db_action = db_action | 1
	WHERE	posted_flag != 1
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 227, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	



	IF (@result = 0)
	BEGIN
		IF EXISTS (	SELECT	err_code
				FROM	#ewerror	)
	 		SELECT @status = 34570
		ELSE
			SELECT @status = 0
	END
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "dumping #artrxage_work...chg records"
		SELECT	"customer_code = " + customer_code +
			"nat_cur_code = " + nat_cur_code +
			"trx_type = " + STR(trx_type, 8)
		FROM	#artrxage_work
		WHERE	trx_type in (2061, 2071)
		
		SELECT	"dumping #cust_info..."
		SELECT	"customer_code = " + customer_code
		FROM	#cust_info
	END

	





	INSERT	#arfin
		(	trx_type,	     	customer_code,	customer_name,
			fin_chg_code,		price_code,		currency_code,	
			user_id,		apply_to_num,		apply_trx_type,	
			sub_apply_to_num,	sub_apply_to_type,	date_aging,		
			date_due,		amount,		rate,			
			overdue_amt,		
			chrg_days,				
			currency_mask,	
			amount_home,
			org_id
		)
	SELECT	      chg.trx_type,		chg.customer_code,	cust.customer_name,
		      cust.fin_chg_code,	chg.price_code,	chg.nat_cur_code,
		      0,			chg.apply_to_num,	chg.apply_trx_type,
		      chg.sub_apply_num,	chg.sub_apply_type,	chg.date_aging,	
		      chg.date_due,		chg.amount,		0.0,		
		      cust.overdue_amt,
		      chg.group_id,		
		      gl.currency_mask,
		      ROUND(chg.amount*( SIGN(1 + SIGN(chg.rate_home))*(chg.rate_home) + (SIGN(ABS(SIGN(ROUND(chg.rate_home,6))))/(chg.rate_home + SIGN(1 - ABS(SIGN(ROUND(chg.rate_home,6)))))) * SIGN(SIGN(chg.rate_home) - 1) ), gl.curr_precision),
		      chg.org_id
	FROM	#artrxage_work chg, #cust_info cust, glcurr_vw gl
	WHERE	chg.trx_type >= 2061
	AND	chg.trx_type <= 2071
	AND	chg.customer_code = cust.customer_code
	AND	chg.nat_cur_code = gl.currency_code
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 294, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	UPDATE	#artrxage_work
	SET	group_id = 0
	WHERE	trx_type = 2061
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 304, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	DROP TABLE #cust_info
	
	


	UPDATE	#arfin
	SET	fin_chg_code = inv.fin_chg_code,
		user_id = inv.user_id
	FROM	#artrx_work inv
	WHERE	#arfin.trx_type = 2061
	AND	#arfin.sub_apply_to_num = inv.doc_ctrl_num
	AND	#arfin.sub_apply_to_type = inv.trx_type
	AND	inv.trx_type <= 2031
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 324, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	


	UPDATE	#arfin
	SET	rate = fin.fin_chg_prc,
		overdue_amt = (inv.amount + inv.amt_fin_chg*fin.compound_chg_flag - inv.amt_paid)
	FROM	#artrxage_work inv, arfinchg fin
	WHERE	#arfin.sub_apply_to_num = inv.doc_ctrl_num
	AND	#arfin.sub_apply_to_type = inv.trx_type
	AND	#arfin.date_aging = inv.date_aging
	AND	#arfin.trx_type = 2061
	AND	#arfin.fin_chg_code = fin.fin_chg_code
	AND	inv.trx_type >= 2021
	AND	inv.trx_type <= 2031
	
	


	UPDATE	#arfin
	SET	overdue_amt = (inv.amt_tot_chg - inv.amt_paid_to_date),
		fin_chg_code = inv.fin_chg_code
	FROM	#artrx_work inv
	WHERE	#arfin.trx_type = 2071
	AND	#arfin.apply_to_num = inv.doc_ctrl_num
	AND	#arfin.apply_trx_type = inv.trx_type
	AND	inv.trx_type >= 2021
	AND	inv.trx_type <= 2031
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 358, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	IF ( @debug_level > 2 )
	BEGIN
		SELECT "dumping #arfin..."
		SELECT	"customer_code = " + customer_code +
			"apply_to_num = " + apply_to_num +
			"overdue_amt = " + STR(overdue_amt, 10, 2) +
			"rate = " + STR(rate, 10, 2) +
			"fin_chg_code = " + fin_chg_code
		FROM	#arfin
	END

	


		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arflpb.cpp" + ", line " + STR( 378, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arflpb.cpp", 379, "Leaving ARFLPostBatch_SP", @PERF_time_last OUTPUT
    	RETURN @validation_status 
	
END
GO
GRANT EXECUTE ON  [dbo].[ARFLPostBatch_SP] TO [public]
GO
