SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMUpdateActivity_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	@result 			int, 
		@process_ctrl_num		varchar( 16),
		@user_id			smallint,
		@date_entered			int,
		@period_end			int,
		@batch_type			smallint

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmua.sp", 69, "Entering ARCMActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "

	
	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@user_id OUTPUT,
					@date_entered OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 84, 5 ) + " -- MSG: " + "After call to batinfo_sp"

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "
		RETURN 35011
	END

	CREATE TABLE #cust_act
	(
		customer_code	varchar( 8 ),
		doc_ctrl_num	varchar( 16 )
	)

	
	INSERT	#cust_act
	(	
		customer_code,	doc_ctrl_num
	)
	SELECT customer_code,	MAX(doc_ctrl_num)
	FROM	#arinpchg_work, arco
	WHERE	arco.aractcus_flag = 1 
	GROUP BY customer_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 111, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	CREATE TABLE #amt_net
	(	
		doc_ctrl_num	varchar( 16 ),
		amt_net	float
	)

	INSERT	#amt_net
	(
		doc_ctrl_num,		amt_net
	)
	SELECT	doc_ctrl_num,		amt_net
	FROM	#arinpchg_work
	WHERE	recurring_flag = 1

	INSERT	#amt_net
	(
		doc_ctrl_num,		amt_net
	)
	SELECT	doc_ctrl_num,		amt_tax
	FROM	#arinpchg_work
	WHERE	recurring_flag = 2
	
	INSERT	#amt_net
	(
		doc_ctrl_num,		amt_net
	)
	SELECT	doc_ctrl_num,		amt_freight
	FROM	#arinpchg_work
	WHERE	recurring_flag = 3

	INSERT	#amt_net
	(
		doc_ctrl_num,		amt_net
	)
	SELECT	doc_ctrl_num,		amt_freight + amt_tax
	FROM	#arinpchg_work
	WHERE	recurring_flag = 4


	CREATE INDEX #cust_act_ind ON #cust_act(customer_code)
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #cust_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 167, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 170, 5 ) + " -- MSG: " + "After insert into #cust_act"

	INSERT	#aractcus_work
	(
		customer_code,
		date_last_cm,
		amt_last_cm,
		last_cm_doc,
		last_cm_cur
	)
	SELECT	arinpchg.customer_code,
		@date_entered,
		#amt_net.amt_net,
		arinpchg.doc_ctrl_num,
		arinpchg.nat_cur_code
	FROM	#arinpchg_work arinpchg, #cust_act, #amt_net
	WHERE	arinpchg.customer_code = #cust_act.customer_code
	AND	arinpchg.doc_ctrl_num = #cust_act.doc_ctrl_num
	AND	arinpchg.doc_ctrl_num = #amt_net.doc_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #cust_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 192, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 195, 5 ) + " -- MSG: " + "After insert into #aractcus_work 1"

	DROP TABLE #cust_act
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 200, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	SELECT price_code, MAX(doc_ctrl_num) doc_ctrl_num
	INTO	#price_act
	FROM	#arinpchg_work, arco
	WHERE	arco.aractprc_flag = 1
	AND	( LTRIM(price_code) IS NOT NULL AND LTRIM(price_code) != " " )
	GROUP BY price_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 215, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	CREATE INDEX #price_act_ind ON #price_act(price_code)
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #price_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 223, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 226, 5 ) + " -- MSG: " + "After select into #prics_act"

	INSERT	#aractprc_work
	(
		price_code,
		date_last_cm,
		amt_last_cm,
		last_cm_doc,
		last_cm_cur
	)
	SELECT	arinpchg.price_code,
		@date_entered,
		#amt_net.amt_net,
		arinpchg.doc_ctrl_num,
		arinpchg.nat_cur_code
	FROM	#arinpchg_work arinpchg, #price_act, #amt_net
	WHERE	arinpchg.price_code = #price_act.price_code
	AND	arinpchg.doc_ctrl_num = #price_act.doc_ctrl_num
	AND	arinpchg.doc_ctrl_num = #amt_net.doc_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #price_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 248, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 251, 5 ) + " -- MSG: " + "After insert into #aractprc_work 2"

	DROP TABLE #price_act
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 256, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 259, 5 ) + " -- MSG: " + "After drop table #price_act 2.1"

	
	CREATE TABLE #shipto_act (ship_to_code varchar(8), doc_ctrl_num varchar(16) )
	IF ( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 267, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT INTO #shipto_act
	(
		ship_to_code,
		doc_ctrl_num
	)
	SELECT arinpchg.ship_to_code,
		max(arinpchg.doc_ctrl_num)
	FROM #arinpchg_work arinpchg, arcust, arco
	WHERE arcust.customer_code = arinpchg.customer_code
	AND arco.aractshp_flag = 1
	AND arcust.ship_to_history = 1
	AND ( LTRIM(arinpchg.ship_to_code) IS NOT NULL AND LTRIM(arinpchg.ship_to_code) != " " )
	GROUP BY arinpchg.ship_to_code

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 285, 5 ) + " -- MSG: " + "Before index creation 2.1.1"
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #shipto_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 289, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 293, 5 ) + " -- MSG: " + "Before index creation 2.1.2"
	CREATE INDEX #shipto_act_ind ON #shipto_act(ship_to_code)
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #shipto_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 298, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 301, 5 ) + " -- MSG: " + "After select into #shipto_act 2.2"

	INSERT	#aractshp_work
	(
		ship_to_code,
		customer_code,
		date_last_cm,
		amt_last_cm,
		last_cm_doc,
		last_cm_cur
	)
	SELECT	arinpchg.ship_to_code,
		arinpchg.customer_code,
		@date_entered,
		#amt_net.amt_net,
		arinpchg.doc_ctrl_num,
		arinpchg.nat_cur_code
	FROM	#arinpchg_work arinpchg, #shipto_act, #amt_net
	WHERE	arinpchg.ship_to_code = #shipto_act.ship_to_code
	AND	arinpchg.doc_ctrl_num = #shipto_act.doc_ctrl_num
	AND	arinpchg.doc_ctrl_num = #amt_net.doc_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #shipto_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 325, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 328, 5 ) + " -- MSG: " + "After insert into #aractshp_work 3"

	DROP TABLE #shipto_act
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 333, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	SELECT salesperson_code, MAX(doc_ctrl_num) doc_ctrl_num
	INTO	#sales_act
	FROM	#arinpchg_work, arco
	WHERE	arco.aractslp_flag = 1
	AND	( LTRIM(salesperson_code) IS NOT NULL AND LTRIM(salesperson_code) != " " )
	GROUP BY salesperson_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 348, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	CREATE INDEX #sales_act_ind ON #sales_act(salesperson_code)
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #sales_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 356, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT	#aractslp_work
	(
		salesperson_code,
		date_last_cm,
		amt_last_cm,
		last_cm_doc,
		last_cm_cur
	)
	SELECT	arinpchg.salesperson_code,
		@date_entered,
		#amt_net.amt_net,
		arinpchg.doc_ctrl_num,
		arinpchg.nat_cur_code
	FROM	#arinpchg_work arinpchg, #sales_act, #amt_net
	WHERE	arinpchg.salesperson_code = #sales_act.salesperson_code
	AND	arinpchg.doc_ctrl_num = #sales_act.doc_ctrl_num
	AND	arinpchg.doc_ctrl_num = #amt_net.doc_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #sales_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 380, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 384, 5 ) + " -- MSG: " + "After insert into #aractslp_work 4"
	DROP TABLE #sales_act
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 388, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	SELECT territory_code, MAX(doc_ctrl_num) doc_ctrl_num
	INTO	#terr_act
	FROM	#arinpchg_work, arco
	WHERE	arco.aractter_flag = 1
	AND	( LTRIM(territory_code) IS NOT NULL AND LTRIM(territory_code) != " " )
	GROUP BY territory_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 404, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	CREATE INDEX #terr_act_ind ON #terr_act(territory_code)
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #terr_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 412, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	INSERT	#aractter_work
	(
		territory_code,
		date_last_cm,
		amt_last_cm,
		last_cm_doc,
		last_cm_cur
	)
	SELECT	arinpchg.territory_code,
		@date_entered,
		#amt_net.amt_net,
		arinpchg.doc_ctrl_num,
		arinpchg.nat_cur_code
	FROM	#arinpchg_work arinpchg, #terr_act, #amt_net
	WHERE	arinpchg.territory_code = #terr_act.territory_code
	AND	arinpchg.doc_ctrl_num = #terr_act.doc_ctrl_num
	AND	arinpchg.doc_ctrl_num = #amt_net.doc_ctrl_num
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #terr_act
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 436, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 440, 5 ) + " -- MSG: " + "After insert into #aractter_work 5"
	DROP TABLE #terr_act
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 444, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	
	DROP TABLE #amt_net

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmua.sp", 455, "Leaving ARCMUpdateActivity_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmua.sp" + ", line " + STR( 456, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMUpdateActivity_SP] TO [public]
GO
