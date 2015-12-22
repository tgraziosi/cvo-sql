SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCreateOnAccountDetails_SP]	@batch_ctrl_num     varchar( 16 ),
						@debug_level        smallint = 0,
						@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcoad.cpp", 69, "Entering ARCMCreateOnAccountDetails_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoad.cpp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "

	




	CREATE TABLE	#amt_net
	(
		trx_ctrl_num	varchar(16),
		trx_type	smallint,
		amt_net	float
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoad.cpp" + ", line " + STR( 87, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	INSERT	#amt_net
	(
		trx_ctrl_num,
		trx_type,
		amt_net
	)
	SELECT	trx_ctrl_num, 
		trx_type, 
		(-1.0 * amt_net) 
	FROM	#arinpchg_work 
	WHERE	recurring_flag = 1
	AND	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #amt_net
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoad.cpp" + ", line " + STR( 109, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	INSERT	#amt_net
	(
		trx_ctrl_num,
		trx_type,
		amt_net
	)
	SELECT	trx_ctrl_num, 
		trx_type, 
		(-1.0 * (amt_tax - amt_discount_taken - amt_write_off_given)) 
	FROM	#arinpchg_work 
	WHERE	recurring_flag = 2
	AND	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #amt_net
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoad.cpp" + ", line " + STR( 131, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	INSERT	#amt_net
	(
		trx_ctrl_num,
		trx_type,
		amt_net
	)
	SELECT	trx_ctrl_num, 
		trx_type, 
		(-1.0 * (amt_freight - amt_discount_taken - amt_write_off_given))
	FROM	#arinpchg_work 
	WHERE	recurring_flag = 3
	AND	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #amt_net
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoad.cpp" + ", line " + STR( 153, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	INSERT	#amt_net
	(
		trx_ctrl_num,
		trx_type,
		amt_net
	)
	SELECT	trx_ctrl_num, 
		trx_type, 
		(-1.0 * (amt_freight + amt_tax - amt_discount_taken - amt_write_off_given))
	FROM	#arinpchg_work 
	WHERE	recurring_flag = 4
	AND	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #amt_net
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoad.cpp" + ", line " + STR( 175, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	INSERT	#argldist
	(
		date_applied,		account_code,			
                description,
		document_1,		document_2,			nat_balance,
		nat_cur_code,		rate_home,			trx_type,
		seq_ref_id,		trx_ctrl_num,			rate_type_home,
		rate_type_oper,	        rate_oper,                      org_id                
	)
	SELECT	h.date_applied,	        dbo.IBAcctMask_fn(acct.cm_on_acct_code, h.org_id),    
                h.doc_desc,
		h.customer_code,	h.doc_ctrl_num,		        net.amt_net,
		h.nat_cur_code,	        rate_home,			h.trx_type,
		0,			net.trx_ctrl_num,		rate_type_home,
		rate_type_oper,	        rate_oper,                      h.org_id        
	FROM	#arinpchg_work h, araccts acct, #amt_net net
	WHERE	h.posting_code = acct.posting_code
	AND	h.trx_ctrl_num = net.trx_ctrl_num
	AND	h.trx_type = net.trx_type
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #amt_net
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoad.cpp" + ", line " + STR( 204, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	DROP TABLE #amt_net
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoad.cpp" + ", line " + STR( 214, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcoad.cpp", 218, "Leaving ARCMCreateOnAccountDetails_SP", @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateOnAccountDetails_SP] TO [public]
GO
