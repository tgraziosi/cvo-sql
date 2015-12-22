SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcomsum_sp]	@t_sys_date int, @t_apply_date int
AS

DECLARE	@last_code char(8), @cur_code char(8),
	@tot_comm float, @line_comm float,
	@lineitem smallint, @invoice smallint, @period smallint,
	@cus_act smallint, @slp_act smallint

SELECT @lineitem = 0, @invoice = 1, @period = 2

SELECT	@cus_act = aractcus_flag,
	@slp_act = aractslp_flag
FROM	arco

BEGIN TRAN

IF @cus_act = 1
BEGIN
	SELECT	@cur_code = SPACE(1)

	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_code = @cur_code
		SELECT	@cur_code = NULL

		SELECT	@cur_code = MIN( customer_code )
		FROM	arsalcom
		WHERE	customer_code > @last_code

		IF @cur_code IS NULL
			BREAK

		SELECT	@tot_comm = NULL
		SELECT	@tot_comm = SUM( net_commission )
		FROM	arsalcom
		WHERE	customer_code = @cur_code
		AND	comm_type in ( 2, 3 )
		AND	table_amt_type in ( @period, @invoice )

		IF @tot_comm IS NULL
			SELECT @tot_comm = 0.0

		SELECT	@line_comm = NULL
		SELECT	@line_comm = SUM( net_commission )
		FROM	arsalcom
		WHERE	customer_code = @cur_code
		AND	comm_type in ( 1, 3 )
		AND	table_amt_type = @lineitem

		IF @line_comm IS NULL
			SELECT @line_comm = 0.0

		SELECT @tot_comm = @tot_comm + @line_comm

		
		IF (ABS((@tot_comm)-(0.0)) < 0.0000001)
			CONTINUE

		UPDATE aractcus
		SET	date_last_comm = @t_sys_date,
			amt_last_comm = @tot_comm
		WHERE	customer_code = @cur_code

		EXEC	arintsum_sp	@cur_code, 
					NULL,	 
					NULL,	 
					NULL,	 
					NULL,	 
					@t_apply_date,
					0, 
					0 

 		UPDATE	arsumcus
		SET	amt_comm = amt_comm + @tot_comm
		WHERE	customer_code = @cur_code
		AND	date_thru = ( SELECT MIN(date_thru)
				 FROM arsumcus
				 WHERE customer_code = @cur_code
				 AND ( @t_apply_date BETWEEN 
				 		date_from AND date_thru ) )
	END
END


IF @slp_act = 1
BEGIN
	SELECT	@cur_code = SPACE(1)

	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_code = @cur_code

		SELECT	@cur_code = NULL
		SELECT	@cur_code = MIN( salesperson_code )
		FROM	arsalcom
		WHERE	salesperson_code > @last_code

		IF @cur_code IS NULL
			BREAK

		SELECT	@tot_comm = NULL
		SELECT	@tot_comm = SUM( net_commission )
		FROM	arsalcom
		WHERE	salesperson_code = @cur_code
		AND	comm_type in ( 2, 3 )
		AND	table_amt_type in ( @period, @invoice )

		IF @tot_comm IS NULL
			SELECT @tot_comm = 0.0

		SELECT	@line_comm = NULL
		SELECT	@line_comm = SUM( net_commission )
		FROM	arsalcom
		WHERE	salesperson_code = @cur_code
		AND	comm_type in ( 1, 3 )
		AND	table_amt_type = @lineitem

		IF @line_comm IS NULL
			SELECT @line_comm = 0.0

		SELECT @tot_comm = @tot_comm + @line_comm

		
		IF (ABS((@tot_comm)-(0.0)) < 0.0000001)
			CONTINUE

		
		IF EXISTS(	SELECT salesperson_code
				FROM	aractslp
				WHERE	salesperson_code = @cur_code
			 )
			UPDATE aractslp
			SET	date_last_comm = @t_sys_date,
				amt_last_comm = @tot_comm
			WHERE	salesperson_code = @cur_code 
		ELSE	
			INSERT	aractslp(
				salesperson_code,	date_last_inv,	date_last_cm,
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
				amt_balance,		amt_age_b1_oper, 
				amt_age_b2_oper,	amt_age_b3_oper,	amt_age_b4_oper, 
				amt_age_b5_oper,	amt_age_b6_oper,	amt_on_order_oper, 
				amt_inv_unp_oper,	high_amt_ar_oper,	high_amt_inv_oper, 
				amt_balance_oper,	last_inv_cur,
				last_cm_cur,		last_adj_cur,		last_wr_off_cur,
				last_pyt_cur,		last_nsf_cur,		last_fin_chg_cur,
				last_late_chg_cur,	last_age_upd_date
			)
			SELECT	@cur_code,		0,			0,
				0,			0,			0,
				0,			0,			0,
				@t_sys_date,		0.0,			0.0,
				0.0,			0.0,			0.0,
				0.0,			0.0,			0.0,
				@tot_comm,		0.0,			0.0,
				0.0,			0.0,			0.0,
				0.0,			0.0,			0.0,
				' ',			' ',			' ',
				' ',			' ',			' ',
				' ',			' ',			0.0,
			 	0.0,			0,			0,
				0,			0,			0,
				0,			0,			0,
				0.0,			0.0,
				0.0,			0.0,			0.0,	
				0.0,			0.0,			0.0,	
				0.0,			0.0,			0.0,	
				0.0,			' ',	
				' ',			' ',			' ',
				' ',			' ',			' ',
				' ',			0
		EXEC	arintsum_sp	NULL,	 
					NULL,	 
					NULL,	 
					@cur_code, 
					NULL,	 
					@t_apply_date,
					0, 
					0 

 		UPDATE	arsumslp
		SET	amt_comm = amt_comm + @tot_comm
		WHERE	salesperson_code = @cur_code
		AND	date_thru = ( SELECT MIN(date_thru)
				 FROM arsumslp
				 WHERE salesperson_code = @cur_code
				 AND ( @t_apply_date BETWEEN 
				 		date_from AND date_thru ) )
	END
END

UPDATE	artrx
SET	commission_flag = 1
WHERE	commission_flag = 2

UPDATE	artrxcom
SET	commission_flag = 1
WHERE	commission_flag = 2

UPDATE	arcomadj
SET	posted_flag = 1
WHERE	posted_flag = 2

COMMIT TRAN

RETURN



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcomsum_sp] TO [public]
GO
