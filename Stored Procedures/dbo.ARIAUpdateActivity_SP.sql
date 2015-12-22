SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAUpdateActivity_SP]	@batch_ctrl_num	varchar( 16 ),
					@perf_level		smallint,
					@debug_level		smallint

AS


DECLARE	@ship_hist_flag	smallint,
		@ar_price_flag	smallint,
		@ar_ship_to_flag	smallint,
		@ar_territory_flag	smallint,
		@ar_salesperson_flag	smallint,
		@result	int

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

	
	SELECT	@ar_salesperson_flag = aractslp_flag,
		@ar_price_flag = aractprc_flag,
		@ar_territory_flag = aractter_flag,
		@ar_ship_to_flag = aractshp_flag
	FROM	arco

	IF ( @@ROWCOUNT = 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 71, 5 ) + " -- EXIT: "
		RETURN 32124
	END

	
	
	INSERT #aractcus_work
	(
		customer_code
	)
	SELECT DISTINCT arinpchg.customer_code
	FROM	#arinpchg_work arinpchg
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE #aractcus_work
	SET	last_adj_doc = ( SELECT max(chg.trx_ctrl_num)
				 FROM #arinpchg_work chg
				 WHERE #aractcus_work.customer_code = chg.customer_code
				 AND chg.trx_type = 2051
				 )
				 
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 104, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	UPDATE	#aractcus_work
	SET	date_last_adj = chg.date_applied,
		amt_last_adj = chg.amt_net,
		last_adj_cur = chg.nat_cur_code,
		last_trx_time = 0
	FROM	#arinpchg_work chg
	WHERE	#aractcus_work.last_adj_doc = chg.trx_ctrl_num
	AND	#aractcus_work.customer_code = chg.customer_code
	AND	chg.trx_type = 2051
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @ar_price_flag > 0 )
	BEGIN
		INSERT #aractprc_work
		(
			price_code
		)
		SELECT DISTINCT chg.price_code
		FROM	#arinpchg_work chg
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.price_code) IS NOT NULL AND LTRIM(chg.price_code) != " " )
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE #aractprc_work
		SET	last_adj_doc = ( SELECT max(chg.trx_ctrl_num)
					 FROM #arinpchg_work chg
					 WHERE #aractprc_work.price_code = chg.price_code
					 AND chg.trx_type = 2051
					 )
					 
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 150, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE	#aractprc_work
		SET	date_last_adj = chg.date_applied,
			amt_last_adj = chg.amt_net,
			last_adj_cur = chg.nat_cur_code,
			last_trx_time = 0
		FROM	#arinpchg_work chg
		WHERE	#aractprc_work.last_adj_doc = chg.trx_ctrl_num
		AND	#aractprc_work.price_code = chg.price_code
		AND	chg.trx_type = 2051
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 166, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	IF ( @ar_salesperson_flag > 0 )
	BEGIN
		INSERT #aractslp_work
		(
			salesperson_code
		)
		SELECT DISTINCT chg.salesperson_code
		FROM	#arinpchg_work chg
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.salesperson_code) IS NOT NULL AND LTRIM(chg.salesperson_code) != " " )
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 184, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE #aractslp_work
		SET	last_adj_doc = ( SELECT max(chg.trx_ctrl_num)
					 FROM #arinpchg_work chg
					 WHERE #aractslp_work.salesperson_code = chg.salesperson_code
					 AND chg.trx_type = 2051
					 )
					 
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 197, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE	#aractslp_work
		SET	date_last_adj = chg.date_applied,
			amt_last_adj = chg.amt_net,
			last_adj_cur = chg.nat_cur_code,
			last_trx_time = 0
		FROM	#arinpchg_work chg
		WHERE	#aractslp_work.last_adj_doc = chg.trx_ctrl_num
		AND	#aractslp_work.salesperson_code = chg.salesperson_code
		AND	chg.trx_type = 2051
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 213, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	IF ( @ar_ship_to_flag > 0 )
	BEGIN
		INSERT #aractshp_work
		(
			customer_code,
			ship_to_code
		)
		SELECT DISTINCT chg.customer_code,
			chg.ship_to_code
		FROM	#arinpchg_work chg
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	chg.trx_type = 2051
		AND	( LTRIM(chg.ship_to_code) IS NOT NULL AND LTRIM(chg.ship_to_code) != " " )
					 
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 234, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE #aractshp_work
		SET	last_adj_doc = (SELECT MAX( trx_ctrl_num )
					 FROM #arinpchg_work chg
					 WHERE #aractshp_work.customer_code = chg.customer_code
					 AND	 #aractshp_work.ship_to_code = chg.ship_to_code
					 AND	 chg.trx_type = 2051 )
					 
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 247, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE	#aractshp_work
		SET	date_last_adj = chg.date_applied,
			amt_last_adj = chg.amt_net,
			last_adj_cur = chg.nat_cur_code,
			last_trx_time = 0
		FROM	#arinpchg_work chg
		WHERE	#aractshp_work.customer_code = chg.customer_code
		AND	#aractshp_work.ship_to_code = chg.ship_to_code
		AND	#aractshp_work.last_adj_doc = chg.trx_ctrl_num
		AND	chg.trx_type = 2051
					 
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 264, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	IF ( @ar_territory_flag > 0 )
	BEGIN
		INSERT #aractter_work
		(
			territory_code
		)
		SELECT DISTINCT chg.territory_code
		FROM	#arinpchg_work chg
		WHERE	chg.batch_code = @batch_ctrl_num
		AND	( LTRIM(chg.territory_code) IS NOT NULL AND LTRIM(chg.territory_code) != " " )
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 282, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE #aractter_work
		SET	last_adj_doc = ( SELECT max(chg.trx_ctrl_num)
					 FROM #arinpchg_work chg
					 WHERE #aractter_work.territory_code = chg.territory_code
					 AND chg.trx_type = 2051
					 )
					 
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 295, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE	#aractter_work
		SET	date_last_adj = chg.date_applied,
			amt_last_adj = chg.amt_net,
			last_adj_cur = chg.nat_cur_code,
			last_trx_time = 0
		FROM	#arinpchg_work chg
		WHERE	#aractter_work.last_adj_doc = chg.trx_ctrl_num
		AND	#aractter_work.territory_code = chg.territory_code
		AND	chg.trx_type = 2051
		
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 311, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 316, 5 ) + " -- MSG: " + "tmp/ariaua.sp" + "successful"
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaua.sp" + ", line " + STR( 317, 5 ) + " -- EXIT: "
	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[ARIAUpdateActivity_SP] TO [public]
GO
