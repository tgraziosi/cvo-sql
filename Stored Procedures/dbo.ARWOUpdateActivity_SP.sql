SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOUpdateActivity_SP] 	@batch_ctrl_num 	varchar(16),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
AS
DECLARE	@home_prec	smallint,
		@oper_prec	smallint,
		@actprc	smallint,
		@actshp	smallint,
		@actslp	smallint,
		@actter	smallint

BEGIN 
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 64, 5 ) + ' -- ENTRY: '

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 66, 5 ) + ' -- MSG: ' + 'batch_ctrl_num = ' + @batch_ctrl_num


	


	SELECT	@actprc = aractprc_flag,
		@actshp = aractshp_flag,
		@actslp = aractslp_flag,
		@actter = aractter_flag
	FROM	arco

	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 80, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	
	SELECT	@home_prec = h.curr_precision,
		@oper_prec = o.curr_precision
	FROM	glco, glcurr_vw h, glcurr_vw o
	WHERE	glco.home_currency = h.currency_code
	AND	glco.oper_currency = o.currency_code

	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 92, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	


	INSERT  #aractcus_work
	(       
		customer_code,
		amt_balance,
		amt_balance_oper,
		num_inv_paid
	)
	SELECT	customer_code,
		SUM((-1) * amt_wr_off),
		SUM((-1) * amt_wr_off_oper),
		SUM(num_wr_off)
	FROM	#arsumcus_work  
	GROUP BY customer_code

	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 115, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	CREATE TABLE #codedocs
	(
		code_num	varchar(8),
		to_code_num	varchar(8) NULL,
		doc		varchar(16),
		ctrl		varchar(16) NULL
	)

	INSERT INTO #codedocs
	(
		code_num,
		doc
	)
	SELECT wk.customer_code,
		MAX(pdt.doc_ctrl_num)
	FROM	#aractcus_work wk, #arinppdt_work pdt, #arinppyt_work pyt
	WHERE	wk.customer_code = pdt.customer_code
	AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pyt.batch_code = @batch_ctrl_num
	GROUP BY wk.customer_code

	UPDATE #codedocs
	SET	ctrl = (SELECT MAX(apply_to_num)
			FROM	#arinppdt_work
			WHERE	#codedocs.code_num = customer_code
			AND	#codedocs.doc = doc_ctrl_num)

	UPDATE	#aractcus_work
	SET	date_last_wr_off = pyt.date_doc,
		amt_last_wr_off = pdt.inv_amt_applied,  
		last_wr_off_doc = sm.doc,
		last_wr_off_cur = pdt.inv_cur_code
	FROM	#arinppdt_work pdt, #arinppyt_work pyt, #codedocs sm
	WHERE	#aractcus_work.customer_code = sm.code_num
	AND	sm.doc = pdt.doc_ctrl_num
	AND	sm.ctrl = pdt.apply_to_num
	AND	pdt.trx_type = 2151
	AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num

	IF (@debug_level >= 2)
	BEGIN
		SELECT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
		SELECT 'values in #codedocs ' + code_num + ' ' + doc + ' ' + ctrl FROM #codedocs
	END
	
	DELETE	#codedocs


	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 169, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	IF (@debug_level >= 2)
	BEGIN
	SELECT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
		SELECT 'date last write off and doc control num from aractcus_work'
		SELECT customer_code + STR(date_last_wr_off, 9) + ' ' +
			STR(amt_last_wr_off, 10, 6) + ' ' +
			last_wr_off_doc + ' ' +
			last_wr_off_cur + ' '
		FROM	#aractcus_work
		SELECT 'customer_code= '+customer_code+
		'amt_balance= '+STR(amt_balance, 10, 2)+
		'amt_balance_oper= '+STR(amt_balance_oper, 10, 2)+
		'num_inv_paid= '+STR(num_inv_paid, 4)
		FROM    #aractcus_work
	END

	


	IF (@actprc = 1)
	BEGIN
		INSERT  #aractprc_work
		(       
			price_code,
	    		amt_balance,
	    		amt_balance_oper,
			num_inv_paid
		)
		SELECT	price_code,
			SUM((-1) * amt_wr_off),
			SUM((-1) * amt_wr_off_oper),
			SUM(num_wr_off)
		FROM	#arsumprc_work  
		GROUP BY price_code

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 210, 5 ) + ' -- EXIT: '
			RETURN 34563
		END


		INSERT INTO #codedocs
		(
			code_num,
			doc
		)
		SELECT wk.price_code,
			MAX(pdt.doc_ctrl_num)
		FROM	#aractprc_work wk, #arinppdt_work pdt, #arinppyt_work pyt, #artrx_work inv
		WHERE	wk.price_code = inv.price_code
		AND	inv.doc_ctrl_num = pdt.apply_to_num
		AND	inv.trx_type = pdt.apply_trx_type
		AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pyt.batch_code = @batch_ctrl_num
		GROUP BY wk.price_code

		UPDATE #codedocs
		SET	ctrl = (SELECT MAX(pdt.apply_to_num)
				FROM	#arinppdt_work pdt, #artrx_work inv
				WHERE	#codedocs.code_num = inv.price_code
				AND	inv.doc_ctrl_num = pdt.apply_to_num
				AND	pdt.trx_type = 2151
				AND	pdt.doc_ctrl_num = #codedocs.doc )

		UPDATE	#aractprc_work
		SET	date_last_wr_off = pyt.date_doc,
			amt_last_wr_off = pdt.inv_amt_applied,  
			last_wr_off_doc = sm.doc,
			last_wr_off_cur = pdt.inv_cur_code
		FROM	#arinppdt_work pdt, #arinppyt_work pyt, #codedocs sm
		WHERE	#aractprc_work.price_code = sm.code_num
		AND	sm.doc = pdt.doc_ctrl_num
		AND	pdt.trx_type = 2151
		AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num

		IF (@debug_level >= 2)
		BEGIN
			SELECT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
			SELECT 'values in #codedocs ' + code_num + ' ' + doc + ' ' + ctrl FROM #codedocs
		END

		DELETE	#codedocs

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 259, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		IF (@debug_level >= 2)
		BEGIN
			SELECT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
			SELECT 'date last write off and doc control num from aractcus_ork'
			SELECT price_code + STR(date_last_wr_off, 9) + ' ' +
				STR(amt_last_wr_off, 10, 6) + ' ' +
				last_wr_off_doc + ' ' +
				last_wr_off_cur + ' '
			FROM	#aractprc_work
		END
	END

	


	IF (@actshp = 1)
	BEGIN
		INSERT  #aractshp_work
		(
			customer_code,
			ship_to_code,
			amt_balance,
			amt_balance_oper,
			num_inv_paid
		)
		SELECT	customer_code,
			ship_to_code,
			SUM((-1) * amt_wr_off),
			SUM((-1) * amt_wr_off_oper),
			SUM(num_wr_off)
		FROM	#arsumshp_work  
		GROUP BY customer_code, ship_to_code

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 298, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		INSERT INTO #codedocs
		(
			code_num,
			doc,
			to_code_num
		)
		SELECT wk.customer_code,
			MAX(pdt.doc_ctrl_num),
			wk.ship_to_code
		FROM	#aractshp_work wk, #arinppdt_work pdt, #arinppyt_work pyt, #artrx_work inv
		WHERE	wk.customer_code = inv.customer_code
		AND	wk.ship_to_code = inv.ship_to_code
		AND	inv.doc_ctrl_num = pdt.apply_to_num
		AND	inv.trx_type = pdt.apply_trx_type
		AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pyt.batch_code = @batch_ctrl_num
		GROUP BY wk.customer_code, wk.ship_to_code

		UPDATE #codedocs
		SET	ctrl = (SELECT MAX(pdt.apply_to_num)
				FROM	#arinppdt_work pdt, #artrx_work inv
				WHERE	#codedocs.doc = pdt.doc_ctrl_num
				AND	#codedocs.code_num = pdt.customer_code
				AND	pdt.apply_to_num = inv.doc_ctrl_num
				AND	pdt.apply_trx_type = inv.trx_type
				AND	#codedocs.code_num = inv.customer_code
				AND	#codedocs.to_code_num = inv.ship_to_code )

		UPDATE	#aractshp_work
		SET	date_last_wr_off = pyt.date_doc,
			amt_last_wr_off = pdt.inv_amt_applied,  
			last_wr_off_doc = pdt.doc_ctrl_num,
			last_wr_off_cur = pdt.inv_cur_code
		FROM	#arinppdt_work pdt, #arinppyt_work pyt, #codedocs sm
		WHERE	#aractshp_work.customer_code = sm.code_num
		AND	#aractshp_work.ship_to_code = sm.to_code_num
		AND	sm.doc = pdt.doc_ctrl_num
		AND	pdt.trx_type = 2151
		AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num

		IF (@debug_level >= 2)
		BEGIN
			SELECT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
			SELECT 'values in #codedocs ' + code_num + ' ' + doc + ' ' + ctrl FROM #codedocs
		END
		
		DELETE	#codedocs

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 352, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		IF (@debug_level >= 2)
		BEGIN
			SELECT 'date last write off and doc control num from aractcus_ork'
			SELECT customer_code + ship_to_code + STR(date_last_wr_off, 9) + ' ' +
				STR(amt_last_wr_off, 10, 6) + ' ' +
				last_wr_off_doc + ' ' +
				last_wr_off_cur + ' '
			FROM	#aractshp_work
		END
	END

	


	IF (@actslp = 1)
	BEGIN
		INSERT  #aractslp_work
		(       
			salesperson_code,
			amt_balance,
			amt_balance_oper,
			num_inv_paid    
		)
		SELECT	salesperson_code,
			SUM((-1) * amt_wr_off),
			SUM((-1) * amt_wr_off_oper),
			SUM(num_wr_off)
		FROM	#arsumslp_work  
		GROUP BY salesperson_code
		
		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 388, 5 ) + ' -- EXIT: '
			RETURN 34563
		END


		INSERT INTO #codedocs
		(
			code_num,
			doc
		)
		SELECT wk.salesperson_code,
			MAX(pdt.doc_ctrl_num)
		FROM	#aractslp_work wk, #arinppdt_work pdt, #arinppyt_work pyt, #artrx_work inv
		WHERE	wk.salesperson_code = inv.salesperson_code
		AND	inv.doc_ctrl_num = pdt.apply_to_num
		AND	inv.trx_type = pdt.apply_trx_type
		AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pyt.batch_code = @batch_ctrl_num
		GROUP BY wk.salesperson_code

		UPDATE #codedocs
		SET	ctrl = (SELECT MAX(pdt.apply_to_num)
				FROM	#arinppdt_work pdt, #artrx_work inv
				WHERE	#codedocs.code_num = inv.salesperson_code
				AND	inv.doc_ctrl_num = pdt.apply_to_num
				AND	pdt.trx_type = 2151
				AND	pdt.doc_ctrl_num = #codedocs.doc )

		UPDATE	#aractslp_work
		SET	date_last_wr_off = pyt.date_doc,
			amt_last_wr_off = pdt.inv_amt_applied,  
			last_wr_off_doc = pdt.doc_ctrl_num,
			last_wr_off_cur = pdt.inv_cur_code
		FROM	#arinppdt_work pdt, #arinppyt_work pyt, #codedocs sm
		WHERE	#aractslp_work.salesperson_code = sm.code_num
		AND	sm.doc = pdt.doc_ctrl_num
		AND	pdt.trx_type = 2151
		AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num

		IF (@debug_level >= 2)
		BEGIN
			SELECT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
			SELECT 'values in #codedocs ' + code_num + ' ' + doc + ' ' + ctrl FROM #codedocs
		END

		DELETE	#codedocs

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 437, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		IF (@debug_level >= 2)
		BEGIN
			SELECT 'date last write off and doc control num from aractcus_ork'
			SELECT salesperson_code + STR(date_last_wr_off, 9) + ' ' +
				STR(amt_last_wr_off, 10, 6) + ' ' +
				last_wr_off_doc + ' ' +
				last_wr_off_cur + ' '
			FROM	#aractslp_work
		END
	END

	


	IF (@actter = 1)
	BEGIN
		INSERT  #aractter_work
		(       
			territory_code,
			amt_balance,
			amt_balance_oper,
			num_inv_paid
		)
		SELECT	territory_code,
			SUM((-1) * amt_wr_off),
			SUM((-1) * amt_wr_off_oper),
			SUM(num_wr_off)
		FROM	#arsumter_work  
		GROUP BY territory_code
		
		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 473, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		INSERT INTO #codedocs
		(
			code_num,
			doc
		)
		SELECT wk.territory_code,
			MAX(pdt.doc_ctrl_num)
		FROM	#aractter_work wk, #arinppdt_work pdt, #arinppyt_work pyt, #artrx_work inv
		WHERE	wk.territory_code = inv.territory_code
		AND	inv.doc_ctrl_num = pdt.apply_to_num
		AND	inv.trx_type = pdt.apply_trx_type
		AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pyt.batch_code = @batch_ctrl_num
		GROUP BY wk.territory_code

		UPDATE #codedocs
		SET	ctrl = (SELECT MAX(pdt.apply_to_num)
				FROM	#arinppdt_work pdt, #artrx_work inv
				WHERE	#codedocs.code_num = inv.territory_code
				AND	inv.doc_ctrl_num = pdt.apply_to_num
				AND	pdt.trx_type = 2151
				AND	pdt.doc_ctrl_num = #codedocs.doc )

		UPDATE	#aractter_work
		SET	date_last_wr_off = pyt.date_doc,
			amt_last_wr_off = pdt.inv_amt_applied,  
			last_wr_off_doc = pdt.doc_ctrl_num,
			last_wr_off_cur = pdt.inv_cur_code
		FROM	#arinppdt_work pdt, #arinppyt_work pyt, #codedocs sm
		WHERE	#aractter_work.territory_code = sm.code_num
		AND	sm.doc = pdt.doc_ctrl_num 
		AND	pdt.trx_type = 2151
		AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num

		IF (@@error != 0)
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 513, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		IF (@debug_level >= 2)
		BEGIN
			SELECT '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
			SELECT 'values in #codedocs ' + code_num + ' ' + doc + ' ' + ctrl FROM #codedocs
		END
		
		DELETE	#codedocs


		IF (@debug_level >= 2)
		BEGIN
			SELECT 'date last write off and doc control num from aractcus_ork'
			SELECT territory_code + STR(date_last_wr_off, 9) + ' ' +
				STR(amt_last_wr_off, 10, 6) + ' ' +
				last_wr_off_doc + ' ' +
				last_wr_off_cur + ' '
			FROM	#aractter_work
		END
	END
	
	DROP TABLE #codedocs

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwoua.cpp' + ', line ' + STR( 539, 5 ) + ' -- EXIT: '
	RETURN 0


END
GO
GRANT EXECUTE ON  [dbo].[ARWOUpdateActivity_SP] TO [public]
GO
