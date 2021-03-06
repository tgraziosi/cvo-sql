SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                





					


CREATE VIEW [dbo].[apvn1_vw]
AS
SELECT	
	apmaster.vendor_code,  		
	apmaster.address_name,   	    
	
	
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
	high_amt_ap_oper, 

	x_date_last_vouch=date_last_vouch,
	x_date_last_dm=date_last_dm,
	x_date_last_adj=date_last_adj,
	x_date_last_pyt=date_last_pyt,
	x_date_last_void=date_last_void, 
	
	
	x_amt_last_vouch=amt_last_vouch,
	x_amt_last_dm=amt_last_dm,
	x_amt_last_adj=amt_last_adj,
	x_amt_last_pyt=amt_last_pyt,
	x_amt_last_void=amt_last_void,
	x_amt_age_bracket1=amt_age_bracket1,
	x_amt_age_bracket2=amt_age_bracket2,
	x_amt_age_bracket3=amt_age_bracket3,
	x_amt_age_bracket4=amt_age_bracket4,
	x_amt_age_bracket5=amt_age_bracket5,
	x_amt_age_bracket6=amt_age_bracket6,
	x_amt_on_order=amt_on_order,
	x_amt_vouch_unposted=amt_vouch_unposted, 
	
	x_high_amt_ap=high_amt_ap,
	x_high_amt_vouch=high_amt_vouch, 
	
	
	x_high_date_ap=high_date_ap,
	x_high_date_vouch=high_date_vouch, 
	
	
	x_num_vouch=num_vouch,
	x_num_vouch_paid=num_vouch_paid,
	x_num_overdue_pyt=num_overdue_pyt,
	x_avg_days_pay=avg_days_pay,
	x_avg_days_overdue=avg_days_overdue, 
	
	
	 
	x_amt_balance=amt_balance,
	
	
	x_amt_age_bracket1_oper=amt_age_bracket1_oper,
	x_amt_age_bracket2_oper=amt_age_bracket2_oper,
	x_amt_age_bracket3_oper=amt_age_bracket3_oper,
	x_amt_age_bracket4_oper=amt_age_bracket4_oper,
	x_amt_age_bracket5_oper=amt_age_bracket5_oper,
	x_amt_age_bracket6_oper=amt_age_bracket6_oper,
	x_amt_balance_oper=amt_balance_oper,
	x_amt_on_order_oper=amt_on_order_oper,
	x_amt_vouch_unposted_oper=amt_vouch_unposted_oper,
	x_high_amt_ap_oper=high_amt_ap_oper

	
FROM	apmaster LEFT OUTER JOIN apactvnd on (apmaster.vendor_code = apactvnd.vendor_code)
WHERE	address_type = 0

GO
GRANT REFERENCES ON  [dbo].[apvn1_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apvn1_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvn1_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvn1_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvn1_vw] TO [public]
GO
