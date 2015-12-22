SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[artrxxtr_sp]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
WITH RECOMPILE
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()



DECLARE
	@status 	int

SELECT 	@status = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/artrxxtr.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxxtr.sp", 44, "entry artrxxtr_sp", @PERF_time_last OUTPUT



DELETE	artrxxtr
FROM	#artrxxtr_work a, artrxxtr b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num
AND	a.trx_type = b.trx_type
AND	db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxxtr.sp", 64, "delete artrxxtr: delete action", @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	artrxxtr 
	( 
	 	rec_set,
	 	amt_due,
	 	amt_paid,
	 	trx_type,
	 	trx_ctrl_num,
	 	addr1,
	 	addr2,
	 	addr3,
	 	addr4,
	 	addr5,
	 	addr6,
	 	ship_addr1,
	 	ship_addr2,
	 	ship_addr3,
	 	ship_addr4,
	 	ship_addr5,
	 	ship_addr6,
	 	attention_name,
	 	attention_phone,
		customer_country_code,
		customer_city,
		customer_state,
		customer_postal_code,
		ship_to_country_code,
		ship_to_city,
		ship_to_state,
		ship_to_postal_code
	)
	SELECT		 
	   	a.rec_set,
	   	a.amt_due,
	   	a.amt_paid,
	   	a.trx_type,
	   	a.trx_ctrl_num,
	   	a.addr1,
	   	a.addr2,
	   	a.addr3,
	   	a.addr4,
	   	a.addr5,
	   	a.addr6,
	   	a.ship_addr1,
	   	a.ship_addr2,
	   	a.ship_addr3,
	   	a.ship_addr4,
	   	a.ship_addr5,
	   	a.ship_addr6,
	   	a.attention_name,
	   	a.attention_phone,
		a.customer_country_code,
		a.customer_city,
		a.customer_state,
		a.customer_postal_code,
		a.ship_to_country_code,
		a.ship_to_city,
		a.ship_to_state,
		a.ship_to_postal_code
	FROM	#artrxxtr_work a
	WHERE	
		db_action > 0
	AND 	db_action < 4

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxxtr.sp", 116, "insert artrxxtr: insert action", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/artrxxtr.sp", 121, "exit artrxxtr_sp", @PERF_time_last OUTPUT
RETURN @status

GO
GRANT EXECUTE ON  [dbo].[artrxxtr_sp] TO [public]
GO
