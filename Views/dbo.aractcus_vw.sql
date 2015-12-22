SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\aractcus.VWv - e7.2.2 : 1.11
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                





CREATE VIEW	[dbo].[aractcus_vw]
AS
SELECT	
	armaster.customer_code,
	customer_name = armaster.address_name,
	date_last_inv,
	date_last_cm,
	date_last_adj,
	date_last_wr_off,
	date_last_pyt,
	date_last_nsf,
	date_last_fin_chg,
	date_last_late_chg,
	date_last_comm,
	amt_last_inv,
	amt_last_cm,
	amt_last_adj,
	amt_last_wr_off,
	amt_last_pyt,
	amt_last_nsf,
	amt_last_fin_chg,
	amt_last_late_chg,
	amt_last_comm,
	last_inv_doc,
	last_cm_doc,
	last_adj_doc,
	last_wr_off_doc,
	last_pyt_doc,
	last_nsf_doc,
	last_fin_chg_doc,
	last_late_chg_doc,
	high_amt_inv,
	high_date_ar,
	high_date_inv,
	num_inv,
	num_inv_paid,
	num_overdue_pyt,
	avg_days_pay,
	avg_days_overdue,
	last_trx_time,
	last_inv_cur,
	last_cm_cur,
	last_adj_cur,
	last_wr_off_cur,
	last_pyt_cur,
	last_nsf_cur,
	last_fin_chg_cur,
	last_late_chg_cur,
	credit_limit = check_credit_limit * credit_limit,
	limit_by_home,
	last_age_upd_date
FROM	armaster, aractcus
WHERE	armaster.customer_code = aractcus.customer_code
AND	armaster.address_type = 0


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[aractcus_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aractcus_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aractcus_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aractcus_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aractcus_vw] TO [public]
GO
