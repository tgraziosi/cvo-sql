SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[aractprc_sp]	@batch_ctrl_num	varchar( 16 ),
				@debug_level		smallint = 0,
				@perf_level		smallint = 0
WITH RECOMPILE
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@status 	int

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/aractprc.sp" + ", line " + STR( 43, 5 ) + " -- ENTRY: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/aractprc.sp", 44, "entry aractprc_sp", @PERF_time_last OUTPUT
	
	SELECT	@status = 0

	UPDATE	#aractprc_work
	SET	update_flag = 0
	SELECT	@status = @@error

	IF ( @status = 0 )
	BEGIN
		UPDATE	#aractprc_work
		SET	update_flag = 1
		FROM	#aractprc_work a, aractprc b
		WHERE	a.price_code = b.price_code
		SELECT	@status = @@error

		IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp/aractprc.sp", 60, "update #aractprc_work", @PERF_time_last OUTPUT
	END

	IF ( @status = 0 )
	BEGIN
		INSERT	aractprc
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
			amt_balance,		amt_age_b1_oper, 
			amt_age_b2_oper,	amt_age_b3_oper,	amt_age_b4_oper, 
			amt_age_b5_oper,	amt_age_b6_oper,	amt_on_order_oper, 
			amt_inv_unp_oper,	high_amt_ar_oper,	high_amt_inv_oper, 
			amt_balance_oper,	last_inv_cur,
			last_cm_cur,		last_adj_cur,		last_wr_off_cur,
			last_pyt_cur,		last_nsf_cur,		last_fin_chg_cur,
			last_late_chg_cur,	last_age_upd_date
		)
		SELECT	price_code,		0,			0,
			0,			0,			0,
			0,			0,			0,
			0,			0.0,			0.0,
			0.0,			0.0,			0.0,
			0.0,			0.0,			0.0,
			0.0,			0.0,			0.0,
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

		FROM	#aractprc_work
		WHERE	update_flag = 0
		SELECT	@status = @@error

		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/aractprc.sp", 119, "insert aractprc", @PERF_time_last OUTPUT
	END

	IF ( @status = 0 )
	BEGIN
		UPDATE	aractprc
		SET	date_last_inv = ISNULL(t.date_last_inv, p.date_last_inv),
			date_last_cm = ISNULL(t.date_last_cm, p.date_last_cm),
			date_last_adj = ISNULL(t.date_last_adj, p.date_last_adj),
			date_last_wr_off = ISNULL(t.date_last_wr_off, p.date_last_wr_off),
			date_last_pyt = ISNULL(t.date_last_pyt, p.date_last_pyt),
			date_last_nsf = ISNULL(t.date_last_nsf, p.date_last_nsf),
			date_last_fin_chg = ISNULL(t.date_last_fin_chg, p.date_last_fin_chg),
			date_last_late_chg = ISNULL(t.date_last_late_chg, p.date_last_late_chg),
			date_last_comm = ISNULL(t.date_last_comm, p.date_last_comm),
			amt_last_inv = ISNULL(t.amt_last_inv, p.amt_last_inv),
			amt_last_cm = ISNULL(t.amt_last_cm, p.amt_last_cm),
			amt_last_adj = ISNULL(t.amt_last_adj, p.amt_last_adj),
			amt_last_wr_off = ISNULL(t.amt_last_wr_off, p.amt_last_wr_off),
			amt_last_pyt = ISNULL(t.amt_last_pyt, p.amt_last_pyt),
			amt_last_nsf = ISNULL(t.amt_last_nsf, p.amt_last_nsf),
			amt_last_fin_chg = ISNULL(t.amt_last_fin_chg, p.amt_last_fin_chg),
			amt_last_late_chg = ISNULL(t.amt_last_late_chg, p.amt_last_late_chg),
			amt_last_comm = ISNULL(t.amt_last_comm, p.amt_last_comm),
			amt_age_bracket1 = ISNULL(t.amt_age_bracket1, 0.0) + p.amt_age_bracket1,
			amt_age_bracket2 = ISNULL(t.amt_age_bracket2, 0.0) + p.amt_age_bracket2,
			amt_age_bracket3 = ISNULL(t.amt_age_bracket3, 0.0) + p.amt_age_bracket3,
			amt_age_bracket4 = ISNULL(t.amt_age_bracket4, 0.0) + p.amt_age_bracket4,
			amt_age_bracket5 = ISNULL(t.amt_age_bracket5, 0.0) + p.amt_age_bracket5,
			amt_age_bracket6 = ISNULL(t.amt_age_bracket6, 0.0) + p.amt_age_bracket6,
			amt_on_order = ISNULL(t.amt_on_order, 0.0) + p.amt_on_order,
			amt_inv_unposted = ISNULL(t.amt_inv_unposted, 0.0) + p.amt_inv_unposted,
			last_inv_doc = ISNULL(t.last_inv_doc, p.last_inv_doc),
			last_cm_doc = ISNULL(t.last_cm_doc, p.last_cm_doc),
			last_adj_doc = ISNULL(t.last_adj_doc, p.last_adj_doc),
			last_wr_off_doc = ISNULL(t.last_wr_off_doc, p.last_wr_off_doc),
			last_pyt_doc = ISNULL(t.last_pyt_doc, p.last_pyt_doc),
			last_nsf_doc = ISNULL(t.last_nsf_doc, p.last_nsf_doc),
			last_fin_chg_doc = ISNULL(t.last_fin_chg_doc, p.last_fin_chg_doc),
			last_late_chg_doc = ISNULL(t.last_late_chg_doc, p.last_late_chg_doc),
			num_inv = p.num_inv + ISNULL(t.num_inv, 0),
			num_inv_paid = p.num_inv_paid + ISNULL(t.num_inv_paid, 0),
			num_overdue_pyt = p.num_overdue_pyt + ISNULL(t.num_overdue_pyt, 0),
			last_trx_time = ISNULL(t.last_trx_time, p.last_trx_time), 
			amt_balance = p.amt_balance + ISNULL(t.amt_balance, 0.0),
			amt_age_b1_oper = p.amt_age_b1_oper + ISNULL(t.amt_age_b1_oper, 0.0), 
			amt_age_b2_oper = p.amt_age_b2_oper + ISNULL(t.amt_age_b2_oper, 0.0), 
			amt_age_b3_oper = p.amt_age_b3_oper + ISNULL(t.amt_age_b3_oper, 0.0), 
			amt_age_b4_oper = p.amt_age_b4_oper + ISNULL(t.amt_age_b4_oper, 0.0), 
			amt_age_b5_oper = p.amt_age_b5_oper + ISNULL(t.amt_age_b5_oper, 0.0), 
			amt_age_b6_oper = p.amt_age_b6_oper + ISNULL(t.amt_age_b6_oper, 0.0), 
			amt_on_order_oper = p.amt_on_order_oper + ISNULL(t.amt_on_order_oper, 0.0), 
			amt_inv_unp_oper = p.amt_inv_unp_oper + ISNULL(t.amt_inv_unp_oper, 0.0), 
			amt_balance_oper = p.amt_balance_oper + ISNULL(t.amt_balance_oper, 0.0), 
			last_inv_cur = ISNULL(t.last_inv_cur, p.last_inv_cur),
			last_cm_cur = ISNULL(t.last_cm_cur, p.last_cm_cur),
			last_adj_cur = ISNULL(t.last_adj_cur, p.last_adj_cur),
			last_wr_off_cur = ISNULL(t.last_wr_off_cur, p.last_wr_off_cur),
			last_pyt_cur = ISNULL(t.last_pyt_cur, p.last_pyt_cur),
			last_nsf_cur = ISNULL(t.last_nsf_cur, p.last_nsf_cur),
			last_fin_chg_cur = ISNULL(t.last_fin_chg_cur, p.last_fin_chg_cur),
			last_late_chg_cur = ISNULL(t.last_late_chg_cur, p.last_late_chg_cur)
		FROM	aractprc p, #aractprc_work t
		WHERE	p.price_code = t.price_code
		SELECT	@status = @@error

		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/aractprc.sp", 185, "update aractprc: delta values", @PERF_time_last OUTPUT
	END

	
	IF( @status = 0 )
	BEGIN
		UPDATE	aractprc
		SET	high_amt_ar = p.amt_balance,
			high_amt_ar_oper = p.amt_balance_oper,
			high_date_ar = ISNULL(t.high_date_ar, p.high_date_ar)
		FROM	aractprc p, #aractprc_work t
		WHERE	p.price_code = t.price_code
	 	AND	p.amt_balance > p.high_amt_ar
		SELECT @status = @@error
	END

	
	IF( @status = 0 )
	BEGIN
		UPDATE	aractprc
		SET	high_amt_inv = t.high_amt_inv,
			high_amt_inv_oper = t.high_amt_inv_oper,
			high_date_inv = t.high_date_inv
		FROM	aractprc p, #aractprc_work t
		WHERE	p.price_code = t.price_code
	 	AND	t.high_amt_inv > p.high_amt_inv
	 	AND	t.high_amt_inv IS NOT NULL
		SELECT @status = @@error
	END

	IF ( @status = 0 )
	BEGIN
		UPDATE	aractprc
		SET avg_days_overdue = ROUND(((p.avg_days_overdue * (p.num_inv_paid - ISNULL(t.num_inv_paid,0)) + 
			 ISNULL(t.sum_days_overdue, 0)) / p.num_inv_paid), 0)
		FROM 	aractprc p, #aractprc_work t
		WHERE 	p.num_inv_paid != 0 
		AND	p.price_code = t.price_code
		SELECT	@status = @@error

		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/aractprc.sp", 229, "update aractprc: avg_days_overdue", @PERF_time_last OUTPUT

	END

	IF ( @status = 0 )
	BEGIN
		UPDATE	aractprc
 		SET	avg_days_pay = ROUND(((p.avg_days_pay * (p.num_inv_paid - ISNULL(t.num_inv_paid,0)) + 
 					ISNULL(t.sum_days_to_pay_off, 0)) / p.num_inv_paid),0)
		FROM	aractprc p, #aractprc_work t
		WHERE	p.num_inv_paid != 0 
		AND	p.price_code = t.price_code
		SELECT	@status = @@error

		IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/aractprc.sp", 243, "update aractprc: avg_days_pay", @PERF_time_last OUTPUT
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/aractprc.sp", 246, "exit aractprc_sp", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/aractprc.sp" + ", line " + STR( 247, 5 ) + " -- EXIT: "
	RETURN @status
END
GO
GRANT EXECUTE ON  [dbo].[aractprc_sp] TO [public]
GO
