SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\apactcls.VWv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW [dbo].[apactcls_vw]
AS
SELECT	apclass.class_code,
	apclass.description,
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
FROM	apactcls, apclass
WHERE	apactcls.class_code = apclass.class_code


GO
GRANT REFERENCES ON  [dbo].[apactcls_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apactcls_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apactcls_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apactcls_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apactcls_vw] TO [public]
GO
