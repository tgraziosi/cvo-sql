SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arinupa_sp] @module_id int

AS
DECLARE	@cus_flag		smallint,
		@shp_flag		smallint,
		@prc_flag		smallint,
		@ter_flag		smallint,
		@slp_flag		smallint,
		@home_precision	smallint,
		@oper_precision	smallint

BEGIN
	
	SELECT	@cus_flag = 1,
		@shp_flag = aractshp_flag,
		@prc_flag = aractprc_flag,
		@ter_flag = aractter_flag,
		@slp_flag = aractslp_flag
	FROM arco
	
	IF( @@error != 0 )
		RETURN 34563

	SELECT	@home_precision = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.home_currency = glcurr_vw.currency_code
	
	SELECT	@oper_precision = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.oper_currency = glcurr_vw.currency_code



	UPDATE	#arinpchg
	SET	mark_flag = hold_flag*2

	IF( @@error != 0 )
		RETURN 34563

	
	IF (@cus_flag = 1)
	BEGIN
		INSERT	#aritemp
		SELECT customer_code,	
			'',	
			0,
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
		FROM	#arinpchg
		WHERE	hold_flag = 0
		GROUP BY customer_code
		
		IF( @@error != 0 )
			RETURN 34563

		
		UPDATE	#aritemp
		SET	mark_flag = 1
		FROM	aractcus b
		WHERE	#aritemp.code = b.customer_code

		IF( @@error != 0 )
			RETURN 34563

		
		IF ( @module_id = 2000 )
		BEGIN
			
			INSERT	aractcus
			(
				customer_code,		date_last_inv,	date_last_cm,
				date_last_adj,		date_last_wr_off,	date_last_pyt,
				date_last_nsf,		date_last_fin_chg,	date_last_late_chg,
				date_last_comm,		amt_last_inv,		amt_last_cm,
				amt_last_adj,			amt_last_wr_off,	amt_last_pyt,
				amt_last_nsf,			amt_last_fin_chg,	amt_last_late_chg,
				amt_last_comm,		amt_age_bracket1,	amt_age_bracket2,
				amt_age_bracket3,		amt_age_bracket4,	amt_age_bracket5,
				amt_age_bracket6,		amt_on_order,		amt_inv_unposted,
				last_inv_doc,			last_cm_doc,		last_adj_doc,
				last_wr_off_doc,		last_pyt_doc,		last_nsf_doc,
				last_fin_chg_doc,		last_late_chg_doc,	high_amt_ar,
				high_amt_inv,			high_date_ar,		high_date_inv,
				num_inv,			num_inv_paid,		num_overdue_pyt,
				avg_days_pay,			avg_days_overdue,	last_trx_time,
				amt_balance,			amt_on_acct,		amt_age_b1_oper,
				amt_age_b2_oper,		amt_age_b3_oper,	amt_age_b4_oper,
				amt_age_b5_oper,		amt_age_b6_oper,	amt_on_order_oper,
				amt_inv_unp_oper,		high_amt_ar_oper,	high_amt_inv_oper,
				amt_balance_oper,		amt_on_acct_oper,	last_inv_cur,
				last_cm_cur,			last_adj_cur,		last_wr_off_cur,
				last_pyt_cur,			last_nsf_cur,		last_fin_chg_cur,
				last_late_chg_cur,		last_age_upd_date
			)
			SELECT code,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			amt_home,
				'',				'',			'',
				'',				'',			'',
				'',				'',			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0.0,
				0.0,				0.0,			0.0,
				0.0,				0.0,			0.0,
				amt_oper,			0.0,			0.0,
				0.0,				0.0,			'',
				'',				'',			'',
				'',				'',			'',
				'',				0
			FROM #aritemp
			WHERE mark_flag = 0

			IF( @@error != 0 )
				RETURN 34563

			UPDATE	aractcus
			SET	amt_inv_unposted = ISNULL(aractcus.amt_inv_unposted,0.0) + b.amt_home,
				amt_inv_unp_oper = ISNULL(aractcus.amt_inv_unp_oper,0.0) + b.amt_oper
			FROM	#aritemp	b
			WHERE	aractcus.customer_code = b.code
			AND	b.mark_flag = 1

			IF( @@error != 0 )
				RETURN 34563

		END
		
		
		IF ( @module_id = 1000 )
		BEGIN
			UPDATE	aractcus
			SET	amt_inv_unposted = ISNULL(aractcus.amt_inv_unposted,0.0) + b.amt_home,
				amt_inv_unp_oper = ISNULL(aractcus.amt_inv_unp_oper,0.0) + b.amt_oper,
				amt_on_order = ISNULL(aractcus.amt_on_order,0.0) - b.amt_home,
				amt_on_order_oper = ISNULL(aractcus.amt_on_order_oper,0.0) - b.amt_oper
			FROM	#aritemp	b
			WHERE	aractcus.customer_code = b.code
			AND	b.mark_flag = 1
				
			IF( @@error != 0 )
				RETURN 34563
		END

		DELETE #aritemp
		
		
	END


	
	IF (@prc_flag = 1)
	BEGIN
		INSERT	#aritemp
		SELECT price_code,	
			'',	
			0,
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
		FROM	#arinpchg
		WHERE	hold_flag = 0
		AND	( LTRIM(price_code) IS NOT NULL AND LTRIM(price_code) != " " )
		GROUP BY price_code
		
		IF( @@error != 0 )
			RETURN 34563

		
		UPDATE	#aritemp
		SET	mark_flag = 1
		FROM	aractprc b
		WHERE	#aritemp.code = b.price_code

		IF( @@error != 0 )
			RETURN 34563


		
		IF ( @module_id = 2000 )
		BEGIN
			
			INSERT aractprc
			(
				price_code,		date_last_inv,	date_last_cm,
				date_last_adj,	date_last_wr_off,	date_last_pyt,
				date_last_nsf,	date_last_fin_chg,	date_last_late_chg,
				date_last_comm,	amt_last_inv,		amt_last_cm,
				amt_last_adj,		amt_last_wr_off,	amt_last_pyt,
				amt_last_nsf,		amt_last_fin_chg,	amt_last_late_chg,
				amt_last_comm,	amt_age_bracket1,	amt_age_bracket2,
				amt_age_bracket3,	amt_age_bracket4,	amt_age_bracket5,
				amt_age_bracket6,	amt_on_order,		amt_inv_unposted,
				last_inv_doc,		last_cm_doc,		last_adj_doc,
				last_wr_off_doc,	last_pyt_doc,		last_nsf_doc,
				last_fin_chg_doc,	last_late_chg_doc,	high_amt_ar,
				high_amt_inv,		high_date_ar,		high_date_inv,
				num_inv,		num_inv_paid,		num_overdue_pyt,
				avg_days_pay,		avg_days_overdue,	last_trx_time,
				amt_balance,		amt_age_b1_oper,	amt_age_b2_oper,
				amt_age_b3_oper,	amt_age_b4_oper,	amt_age_b5_oper,
				amt_age_b6_oper,	amt_on_order_oper,	amt_inv_unp_oper,
				high_amt_ar_oper,	high_amt_inv_oper,	amt_balance_oper,
				last_inv_cur,		last_cm_cur,		last_adj_cur,
				last_wr_off_cur,	last_pyt_cur,		last_nsf_cur,
				last_fin_chg_cur,	last_late_chg_cur,	last_age_upd_date 
				)
			SELECT code,			0,			0,
				0,			0,			0,
				0,			0,			0,
				0,			0,			0,
				0,			0,			0,
				0,			0,			0,
				0,			0,			0,
				0,			0,			0,
				0,			0,			amt_home,
				'',			'',			'',
				'',			'',			'',
				'',			'',			0,
				0,			0,			0,
				0,			0,			0,
				0,			0,			0,
				0,			0.0,			0.0,
				0.0,			0.0,			0.0,
				0.0,			0.0,			amt_oper,
				0.0,			0.0,			0.0,
				'',			'',			'',
				'',			'',			'',
				'',			'',			0
			FROM	#aritemp
			WHERE	mark_flag = 0

			IF( @@error != 0 )
				RETURN 34563

			UPDATE	aractprc
			SET	amt_inv_unposted = aractprc.amt_inv_unposted + b.amt_home,
				amt_inv_unp_oper = aractprc.amt_inv_unp_oper + b.amt_oper
			FROM	#aritemp b
			WHERE	aractprc.price_code = b.code
			AND	b.mark_flag = 1
			
			IF( @@error != 0 )
				RETURN 34563
		
		END

		
		IF ( @module_id = 1000 )
		BEGIN
			UPDATE	aractprc
			SET	amt_inv_unposted = ISNULL(aractprc.amt_inv_unposted,0.0) + b.amt_home,
				amt_inv_unp_oper = ISNULL(aractprc.amt_inv_unp_oper,0.0) + b.amt_oper,
				amt_on_order = ISNULL(aractprc.amt_on_order,0.0) - b.amt_home,
				amt_on_order_oper = ISNULL(aractprc.amt_on_order_oper,0.0) - b.amt_oper
			FROM	#aritemp	b
			WHERE	aractprc.price_code = b.code
			AND	b.mark_flag = 1
		
			IF( @@error != 0 )
				RETURN 34563
		END

		DELETE #aritemp

	END

	
	IF (@shp_flag = 1)
	BEGIN
		INSERT	#aritemp
		SELECT	customer_code,	
			ship_to_code,
			0,	
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
		FROM	#arinpchg
		WHERE	hold_flag = 0
		AND	( LTRIM(ship_to_code) IS NOT NULL AND LTRIM(ship_to_code) != " " )
		GROUP BY customer_code,ship_to_code
		
		IF( @@error != 0 )
			RETURN 34563

		
		UPDATE	#aritemp
		SET	mark_flag = 1
		FROM	aractshp b
		WHERE	#aritemp.code = b.customer_code
		AND	#aritemp.code2 = b.ship_to_code
		
		IF( @@error != 0 )
			RETURN 34563


		
		IF ( @module_id = 2000 )
		BEGIN
			
			INSERT	aractshp
			(
				customer_code,		ship_to_code,		date_last_inv,
				date_last_cm,			date_last_adj,	date_last_wr_off,
				date_last_pyt,		date_last_nsf,	date_last_fin_chg,
				date_last_late_chg,		date_last_comm,	amt_last_inv,
				amt_last_cm,			amt_last_adj,		amt_last_wr_off,
				amt_last_pyt,			amt_last_nsf,		amt_last_fin_chg,
				amt_last_late_chg,		amt_last_comm,	amt_age_bracket1,
				amt_age_bracket2,		amt_age_bracket3,	amt_age_bracket4,
				amt_age_bracket5,		amt_age_bracket6,	amt_on_order,
				amt_inv_unposted,		last_inv_doc,		last_cm_doc,
				last_adj_doc,			last_wr_off_doc,	last_pyt_doc,
				last_nsf_doc,			last_fin_chg_doc,	last_late_chg_doc,
				high_amt_ar,			high_amt_inv,		high_date_ar,
				high_date_inv,		num_inv,		num_inv_paid,
				num_overdue_pyt,		avg_days_pay,		avg_days_overdue,
				last_trx_time,		amt_balance,		amt_age_b1_oper,
				amt_age_b2_oper,		amt_age_b3_oper,	amt_age_b4_oper,
				amt_age_b5_oper,		amt_age_b6_oper,	amt_on_order_oper,
				amt_inv_unp_oper,		high_amt_ar_oper,	high_amt_inv_oper,
				amt_balance_oper,		last_inv_cur,		last_cm_cur,
				last_adj_cur,			last_wr_off_cur,	last_pyt_cur,
				last_nsf_cur,			last_fin_chg_cur,	last_late_chg_cur,
				last_age_upd_date 
			)
			SELECT code,				code2,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				amt_home,			'',			'',
				'',				'',			'',
				'',				'',			'',
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0.0,
				0.0,				0.0,			0.0,
				0.0,				0.0,			0.0,
				amt_oper,			0.0,			0.0,
				0.0,				'',			'',
				'',				'',			'',
				'',				'',			'',
				0
			FROM	#aritemp
			WHERE	mark_flag = 0

			IF( @@error != 0 )
				RETURN 34563

			UPDATE	aractshp
			SET	amt_inv_unposted = aractshp.amt_inv_unposted + b.amt_home,
				amt_inv_unp_oper = aractshp.amt_inv_unp_oper + b.amt_oper
			FROM	#aritemp b
			WHERE	aractshp.customer_code = b.code
			AND	aractshp.ship_to_code = b.code2
			AND	b.mark_flag = 1
		
			IF( @@error != 0 )
				RETURN 34563

		END
		
		
		IF ( @module_id = 1000 )
		BEGIN
			UPDATE	aractshp
			SET	amt_inv_unposted = ISNULL(aractshp.amt_inv_unposted,0.0) + b.amt_home,
				amt_inv_unp_oper = ISNULL(aractshp.amt_inv_unp_oper,0.0) + b.amt_oper,
				amt_on_order = ISNULL(aractshp.amt_on_order,0.0) - b.amt_home,
				amt_on_order_oper = ISNULL(aractshp.amt_on_order_oper,0.0) - b.amt_oper
			FROM	#aritemp	b
			WHERE	aractshp.customer_code = b.code
			AND	aractshp.ship_to_code = b.code2
			AND	b.mark_flag = 1
		
			IF( @@error != 0 )
				RETURN 34563
		END

		DELETE #aritemp
		
	END

	
	IF (@slp_flag = 1)
	BEGIN
		INSERT	#aritemp
		SELECT	salesperson_code,	
			'',
			0,	
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
		FROM	#arinpchg
		WHERE	hold_flag = 0
		AND	( LTRIM(salesperson_code) IS NOT NULL AND LTRIM(salesperson_code) != " " ) 
		GROUP BY salesperson_code

		IF( @@error != 0 )
			RETURN 34563


		
		UPDATE	#aritemp
		SET	mark_flag = 1
		FROM	aractslp b
		WHERE	#aritemp.code = b.salesperson_code
		
		IF( @@error != 0 )
			RETURN 34563

		
		IF ( @module_id = 2000 )
		BEGIN
			
			INSERT	aractslp
			(
				salesperson_code,		date_last_inv,	date_last_cm,
				date_last_adj,		date_last_wr_off,	date_last_pyt,
				date_last_nsf,		date_last_fin_chg,	date_last_late_chg,
				date_last_comm,		amt_last_inv,		amt_last_cm,
				amt_last_adj,			amt_last_wr_off,	amt_last_pyt,
				amt_last_nsf,			amt_last_fin_chg,	amt_last_late_chg,
				amt_last_comm,		amt_age_bracket1,	amt_age_bracket2,
				amt_age_bracket3,		amt_age_bracket4,	amt_age_bracket5,
				amt_age_bracket6,		amt_on_order,		amt_inv_unposted,
				last_inv_doc,			last_cm_doc,		last_adj_doc,
				last_wr_off_doc,		last_pyt_doc,		last_nsf_doc,
				last_fin_chg_doc,		last_late_chg_doc,	high_amt_ar,
				high_amt_inv,			high_date_ar,		high_date_inv,
				num_inv,			num_inv_paid,		num_overdue_pyt,
				avg_days_pay,			avg_days_overdue,	last_trx_time,
				amt_balance,			amt_age_b1_oper,	amt_age_b2_oper,
				amt_age_b3_oper,		amt_age_b4_oper,	amt_age_b5_oper,
				amt_age_b6_oper,		amt_on_order_oper,	amt_inv_unp_oper,
				high_amt_ar_oper,		high_amt_inv_oper,	amt_balance_oper,
				last_inv_cur,			last_cm_cur,		last_adj_cur,
				last_wr_off_cur,		last_pyt_cur,		last_nsf_cur,
				last_fin_chg_cur,		last_late_chg_cur,	last_age_upd_date 
			)
			SELECT code,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				'',				'',			'',
				'',				'',			'',
				'',				'',			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0.0,			0.0,
				0.0,				0.0,			0.0,
				0.0,				0.0,			0.0,
				0.0,				0.0,			0.0,
				'',				'',			'',
				'',				'',			'',
				'',				'',			0
			FROM	#aritemp
			WHERE	mark_flag = 0
			
			IF( @@error != 0 )
				RETURN 34563


			UPDATE	aractslp
			SET	amt_inv_unposted = aractslp.amt_inv_unposted + b.amt_home,
				amt_inv_unp_oper = aractslp.amt_inv_unp_oper + b.amt_oper
			FROM	#aritemp	b
			WHERE	aractslp.salesperson_code = b.code
			AND	b.mark_flag = 1

			IF( @@error != 0 )
				RETURN 34563
		END
		
		IF ( @module_id = 1000 )
		BEGIN
			UPDATE	aractslp
			SET	amt_inv_unposted = ISNULL(aractslp.amt_inv_unposted,0.0) + b.amt_home,
				amt_inv_unp_oper = ISNULL(aractslp.amt_inv_unp_oper,0.0) + b.amt_oper,
				amt_on_order = ISNULL(aractslp.amt_on_order,0.0) - b.amt_home,
				amt_on_order_oper = ISNULL(aractslp.amt_on_order_oper,0.0) - b.amt_oper
			FROM	#aritemp	b
			WHERE	aractslp.salesperson_code = b.code
			AND	b.mark_flag = 1
		
			IF( @@error != 0 )
				RETURN 34563
		END

		DELETE #aritemp

	END

	
	IF (@ter_flag = 1)
	BEGIN
		INSERT	#aritemp
		SELECT	territory_code,	
			'',
			0,	
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
			SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
		FROM	#arinpchg
		WHERE	hold_flag = 0
		AND	( LTRIM(territory_code) IS NOT NULL AND LTRIM(territory_code) != " " ) 
		GROUP BY territory_code

		IF( @@error != 0 )
			RETURN 34563

		
		UPDATE	#aritemp
		SET	mark_flag = 1
		FROM	aractter b
		WHERE	#aritemp.code = b.territory_code
		
		IF( @@error != 0 )
			RETURN 34563


		
		IF ( @module_id = 2000 )
		BEGIN
			
			INSERT	aractter
			(
				territory_code,		date_last_inv,	date_last_cm,
				date_last_adj,		date_last_wr_off,	date_last_pyt,
				date_last_nsf,		date_last_fin_chg,	date_last_late_chg,
				date_last_comm,		amt_last_inv,		amt_last_cm,
				amt_last_adj,			amt_last_wr_off,	amt_last_pyt,
				amt_last_nsf,			amt_last_fin_chg,	amt_last_late_chg,
				amt_last_comm,		amt_age_bracket1,	amt_age_bracket2,
				amt_age_bracket3,		amt_age_bracket4,	amt_age_bracket5,
				amt_age_bracket6,		amt_on_order,		amt_inv_unposted,
				last_inv_doc,			last_cm_doc,		last_adj_doc,
				last_wr_off_doc,		last_pyt_doc,		last_nsf_doc,
				last_fin_chg_doc,		last_late_chg_doc,	high_amt_ar,
				high_amt_inv,			high_date_ar,		high_date_inv,
				num_inv,			num_inv_paid,		num_overdue_pyt,
				avg_days_pay,			avg_days_overdue,	last_trx_time,
				amt_balance,			amt_age_b1_oper,	amt_age_b2_oper,
				amt_age_b3_oper,		amt_age_b4_oper,	amt_age_b5_oper,
				amt_age_b6_oper,		amt_on_order_oper,	amt_inv_unp_oper,
				high_amt_ar_oper,		high_amt_inv_oper,	amt_balance_oper,
				last_inv_cur,			last_cm_cur,		last_adj_cur,
				last_wr_off_cur,		last_pyt_cur,		last_nsf_cur,
				last_fin_chg_cur,		last_late_chg_cur,	last_age_upd_date 
			)
			SELECT code,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			amt_home,
				'',				'',			'',
				'',				'',			'',
				'',				'',			0,
				0,				0,			0,
				0,				0,			0,
				0,				0,			0,
				0,				0.0,			0.0,
				0.0,				0.0,			0.0,
				0.0,				0.0,			amt_oper,
				0.0,				0.0,			0.0,
				'',				'',			'',
				'',				'',			'',
				'',				'',			0
			FROM	#aritemp
			WHERE	mark_flag = 0
			
			IF( @@error != 0 )
				RETURN 34563


			UPDATE	aractter
			SET	amt_inv_unposted = aractter.amt_inv_unposted + b.amt_home,
				amt_inv_unp_oper = aractter.amt_inv_unp_oper + b.amt_oper
			FROM	#aritemp b
			WHERE	aractter.territory_code = b.code
			AND	b.mark_flag = 1

			IF( @@error != 0 )
				RETURN 34563
		
		END		
		
		
		IF ( @module_id = 1000 )
		BEGIN
			UPDATE	aractter
			SET	amt_inv_unposted = ISNULL(aractter.amt_inv_unposted,0.0) + b.amt_home,
				amt_inv_unp_oper = ISNULL(aractter.amt_inv_unp_oper,0.0) + b.amt_oper,
				amt_on_order = ISNULL(aractter.amt_on_order,0.0) - b.amt_home,
				amt_on_order_oper = ISNULL(aractter.amt_on_order_oper,0.0) - b.amt_oper
			FROM	#aritemp b
			WHERE	aractter.territory_code = b.code
			AND	b.mark_flag = 1
		
			IF( @@error != 0 )
				RETURN 34563
		END

		DELETE #aritemp
		
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[arinupa_sp] TO [public]
GO
