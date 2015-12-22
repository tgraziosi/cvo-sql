SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\apactpto.VWv - e7.2.2 : 1.6
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW [dbo].[apactpto_vw]
AS
SELECT	apvend.vendor_code,
	apvend.vendor_name,
	apvnd_vw.pay_to_code,
	apvnd_vw.pay_to_name,
	date_last_vouch,
	date_last_dm,
	date_last_adj,
	date_last_pyt,
	date_last_void,
	amt_last_vouch,
	amt_last_dm,
	amt_last_adj,
	amt_last_pyt,
	amt_last_void,
	amt_age_bracket1,
	amt_age_bracket2,
	amt_age_bracket3,
	amt_age_bracket4,
	amt_age_bracket5,
	amt_age_bracket6,
	amt_on_order,
	amt_vouch_unposted,
	last_vouch_doc,
	last_dm_doc,
	last_adj_doc,
	last_pyt_doc,
	last_pyt_acct,
	last_void_doc,
	last_void_acct,
	high_amt_ap,
	high_amt_vouch,
	high_date_ap,
	high_date_vouch,
	num_vouch,
	num_vouch_paid,
	num_overdue_pyt,
	avg_days_pay,
	avg_days_overdue,
	last_trx_time,
	amt_balance,
	last_pyt_cur,
	last_vouch_cur,
	last_dm_cur,
	last_adj_cur,
	last_void_cur,
	amt_age_bracket1_oper,
	amt_age_bracket2_oper,
	amt_age_bracket3_oper,
	amt_age_bracket4_oper,
	amt_age_bracket5_oper,
	amt_age_bracket6_oper,
	amt_balance_oper,
	amt_on_order_oper,
	amt_vouch_unposted_oper,
	high_amt_ap_oper 
FROM	apvend, apvnd_vw, apactpto
WHERE	apvend.vendor_code = apactpto.vendor_code
AND	apvnd_vw.pay_to_code = apactpto.pay_to_code


GO
GRANT REFERENCES ON  [dbo].[apactpto_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apactpto_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apactpto_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apactpto_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apactpto_vw] TO [public]
GO
