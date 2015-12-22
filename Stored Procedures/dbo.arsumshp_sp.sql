SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arsumshp_sp]	@batch_ctrl_num	varchar( 16 ),
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsumshp.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsumshp.sp", 45, "entry arsumshp_sp", @PERF_time_last OUTPUT


UPDATE	#arsumshp_work
SET	update_flag = 0

SELECT	@status = @@error

IF ( @status = 0 )
BEGIN
	UPDATE	#arsumshp_work
	SET	update_flag = 1
	FROM	#arsumshp_work a, arsumshp b
	WHERE	a.customer_code = b.customer_code 
	AND	a.ship_to_code = b.ship_to_code
	AND	a.date_thru = b.date_thru

	SELECT	@status = @@error

	IF ( @perf_level >= 3 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsumshp.sp", 64, "update #arsumshp_work", @PERF_time_last OUTPUT
END

IF ( @status = 0 )
BEGIN
	INSERT	arsumshp
		( 
			customer_code,	
			ship_to_code,		date_thru,		date_from,		num_inv,
			num_inv_paid,		num_cm,		num_adj,		num_wr_off ,
			num_pyt,		num_overdue_pyt,	num_nsf,		num_fin_chg,
			num_late_chg,		amt_inv,		amt_cm,		amt_adj,
			amt_wr_off,		amt_pyt,		amt_nsf,		amt_fin_chg,
			amt_late_chg,		amt_profit,		prc_profit,		amt_comm,
			amt_disc_given,	amt_disc_taken,	amt_disc_lost,	amt_freight,
			amt_tax,		avg_days_pay,		avg_days_overdue,	last_trx_time, 
			amt_inv_oper,		amt_cm_oper,		amt_adj_oper,		amt_wr_off_oper,
			amt_pyt_oper,		amt_nsf_oper,		amt_fin_chg_oper,	amt_late_chg_oper,
			amt_disc_g_oper,	amt_disc_t_oper,	amt_freight_oper,	amt_tax_oper		
		)
		SELECT	customer_code, 	
			ship_to_code,		date_thru,		0,	 		0,
		 	0,	 		0,	 		0,	 		0,
		 	0,	 		0,	 		0,	 		0,
		 	0,	 		0.0,	 		0.0,	 		0.0,
		 	0.0,	 		0.0,	 		0.0,	 		0.0,
		 	0.0,	 		0.0,	 		0.0,	 		0.0,
		 	0.0,	 		0.0,	 		0.0,	 		0.0,
		 	0.0,	 		0,	 		0,			0,
			0.0,			0.0,			0.0,			0.0,			
			0.0,			0.0,			0.0,			0.0,			
			0.0,			0.0,			0.0,			0.0			
	FROM 	#arsumshp_work
	WHERE	update_flag = 0	

	SELECT	@status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsumshp.sp", 101, "insert arsumshp", @PERF_time_last OUTPUT
END

IF ( @status = 0 )
BEGIN

	UPDATE	arsumshp
	SET	date_from = ISNULL(t.date_from, p.date_from) ,
		num_inv = p.num_inv + ISNULL(t.num_inv, 0),
		num_inv_paid = p.num_inv_paid + ISNULL(t.num_inv_paid, 0),
		num_cm = p.num_cm + ISNULL(t.num_cm, 0),
		num_adj = p.num_adj + ISNULL(t.num_adj, 0),
		num_wr_off = p.num_wr_off + ISNULL(t.num_wr_off, 0),
		num_pyt = p.num_pyt + ISNULL(t.num_pyt, 0),
		num_overdue_pyt = p.num_overdue_pyt + ISNULL(t.num_overdue_pyt, 0),
		num_nsf = p.num_nsf + ISNULL(t.num_nsf, 0),
		num_late_chg = p.num_late_chg + ISNULL(t.num_late_chg, 0),
		num_fin_chg = p.num_fin_chg + ISNULL(t.num_fin_chg, 0),
		amt_inv = p.amt_inv + ISNULL(t.amt_inv, 0.0),
		amt_cm = p.amt_cm + ISNULL(t.amt_cm, 0.0),
		amt_adj = p.amt_adj + ISNULL(t.amt_adj, 0.0),
		amt_wr_off = p.amt_wr_off + ISNULL(t.amt_wr_off, 0.0),
		amt_pyt = p.amt_pyt + ISNULL(t.amt_pyt, 0.0),
		amt_nsf = p.amt_nsf + ISNULL(t.amt_nsf, 0.0),
		amt_fin_chg = p.amt_fin_chg + ISNULL(t.amt_fin_chg, 0.0),
		amt_late_chg = p.amt_late_chg + ISNULL(t.amt_late_chg, 0.0),
		amt_profit = p.amt_profit + ISNULL(t.amt_profit, 0.0),
		prc_profit = p.prc_profit + ISNULL(t.prc_profit, 0.0),
		amt_comm = p.amt_comm + ISNULL(t.amt_comm, 0.0),
		amt_disc_given = p.amt_disc_given + ISNULL(t.amt_disc_given, 0.0),
		amt_disc_taken = p.amt_disc_taken + ISNULL(t.amt_disc_taken, 0.0),
		amt_disc_lost = p.amt_disc_lost + ISNULL(t.amt_disc_lost, 0.0),
		amt_freight = p.amt_freight + ISNULL(t.amt_freight, 0.0),
		amt_tax = p.amt_tax + ISNULL(t.amt_tax, 0.0),
		amt_inv_oper = p.amt_inv_oper + ISNULL(t.amt_inv_oper, 0.0),
		amt_cm_oper = p.amt_cm_oper + ISNULL(t.amt_cm_oper, 0.0),
		amt_adj_oper = p.amt_adj_oper + ISNULL(t.amt_adj_oper, 0.0),
		amt_wr_off_oper = p.amt_wr_off_oper + ISNULL(t.amt_wr_off_oper, 0.0),
		amt_pyt_oper = p.amt_pyt_oper + ISNULL(t.amt_pyt_oper, 0.0),
		amt_nsf_oper = p.amt_nsf_oper + ISNULL(t.amt_nsf_oper, 0.0),
		amt_fin_chg_oper = p.amt_fin_chg_oper + ISNULL(t.amt_fin_chg_oper, 0.0),
		amt_late_chg_oper = p.amt_late_chg_oper + ISNULL(t.amt_late_chg_oper, 0.0),
		amt_disc_g_oper = p.amt_disc_g_oper + ISNULL(t.amt_disc_g_oper, 0.0),
		amt_disc_t_oper = p.amt_disc_t_oper + ISNULL(t.amt_disc_t_oper, 0.0),
		amt_freight_oper = p.amt_freight_oper + ISNULL(t.amt_freight_oper, 0.0),
		amt_tax_oper = p.amt_tax_oper + ISNULL(t.amt_tax_oper, 0.0),
		last_trx_time = 0
	FROM 	arsumshp p, #arsumshp_work t
	WHERE	p.customer_code = t.customer_code AND
		p.ship_to_code = t.ship_to_code AND
		p.date_thru = t.date_thru

	SELECT @status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsumshp.sp", 155, "update arsumshp: delta fields", @PERF_time_last OUTPUT

END

IF ( @status = 0 )
BEGIN

	UPDATE	arsumshp
 SET 	avg_days_overdue = ROUND(((p.avg_days_overdue * (p.num_inv_paid - ISNULL(t.num_inv_paid,0)) + 
		 	ISNULL(t.sum_days_overdue, 0)) / p.num_inv_paid), 0)
	FROM 	arsumshp p, #arsumshp_work t
	WHERE 	p.num_inv_paid != 0 AND
			p.customer_code = t.customer_code AND
			p.ship_to_code = t.ship_to_code AND
			p.date_thru = t.date_thru

	SELECT @status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsumshp.sp", 173, "update arsumshp: avg_days_overdue", @PERF_time_last OUTPUT


END

IF ( @status = 0 )
BEGIN
	UPDATE	arsumshp
	SET 	avg_days_pay = ROUND(((p.avg_days_pay * (p.num_inv_paid - ISNULL(t.num_inv_paid,0)) + 
 			ISNULL(t.sum_days_to_pay_off, 0)) / p.num_inv_paid),0)
	FROM 	arsumshp p, #arsumshp_work t
	WHERE	p.num_inv_paid != 0 AND
			p.customer_code = t.customer_code AND
			p.ship_to_code = t.ship_to_code AND
			p.date_thru = t.date_thru

	SELECT @status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsumshp.sp", 191, "update arsumshp: avg_days_pay", @PERF_time_last OUTPUT

END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsumshp.sp", 196, "exit arsumshp_sp", @PERF_time_last OUTPUT

RETURN @status
GO
GRANT EXECUTE ON  [dbo].[arsumshp_sp] TO [public]
GO
