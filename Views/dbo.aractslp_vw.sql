SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\aractslp.VWv - e7.2.2 : 1.6
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                





CREATE VIEW	[dbo].[aractslp_vw]
AS
SELECT	
	arsalesp.salesperson_code,
	arsalesp.salesperson_name,
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
	last_pyt_cur,
	last_inv_cur,
	last_cm_cur,
	last_adj_cur,
	last_wr_off_cur,
	last_nsf_cur,
	last_fin_chg_cur,
	last_late_chg_cur,
	last_age_upd_date
FROM	arsalesp, aractslp
WHERE	arsalesp.salesperson_code = aractslp.salesperson_code



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[aractslp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aractslp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aractslp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aractslp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aractslp_vw] TO [public]
GO
