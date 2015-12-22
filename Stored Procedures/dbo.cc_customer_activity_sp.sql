SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_customer_activity_sp] @customer_code varchar(8)
AS		
	SET ROWCOUNT 1
	SELECT 	v.num_inv,
				v.avg_days_overdue,
				v.num_inv_paid,
				v.avg_days_pay,
				v.num_overdue_pyt,
				amt_on_order, 
				amt_inv_unposted, 
				v.high_date_ar,
				high_amt_ar, 
				v.credit_limit,
				v.last_pyt_doc,
				v.date_last_pyt,
				v.last_pyt_cur,
				v.amt_last_pyt,
				v.last_inv_doc,
				v.date_last_inv,
				v.last_inv_cur,
				v.amt_last_inv,
				v.last_cm_doc,
				v.date_last_cm,
				v.last_cm_cur,
				v.amt_last_cm,
				v.last_adj_doc,
				v.date_last_adj,
				v.last_adj_cur,
				v.amt_last_adj,
				v.last_wr_off_doc,
				v.date_last_wr_off,
				v.last_wr_off_cur,
				v.amt_last_wr_off,
				v.last_nsf_doc,
				v.date_last_nsf,
				v.last_nsf_cur,
				v.amt_last_nsf,
				v.last_fin_chg_doc,
				v.date_last_fin_chg,
				v.last_fin_chg_cur,
				v.amt_last_fin_chg,
				v.last_late_chg_doc,
				v.date_last_late_chg,
				v.last_late_chg_cur,
				v.amt_last_late_chg,
				v.date_last_comm,
				home_currency,
				v.amt_last_comm,
				v.last_age_upd_date,
				v.customer_name,
				v.high_amt_inv,
				v.high_date_inv,
				v.limit_by_home
	FROM 		aractcus_vw v, aractcus t, glco
	WHERE 	v.customer_code = @customer_code
	AND		v.customer_code = t.customer_code

	SET ROWCOUNT 0
GO
GRANT EXECUTE ON  [dbo].[cc_customer_activity_sp] TO [public]
GO
