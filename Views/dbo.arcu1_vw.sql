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




					



CREATE VIEW [dbo].[arcu1_vw] as
  SELECT   
  	t1.address_name, 		  
  	t1.customer_code, 		   
  	
	
	t2.amt_on_order,  
	t2.amt_inv_unposted, 
	t2.num_inv,
	t2.num_inv_paid,
	t2.num_overdue_pyt,
	t2.avg_days_pay,
	t2.avg_days_overdue, 
	
	
	t2.amt_age_bracket1, 
	t2.amt_age_bracket2, 
	t2.amt_age_bracket3,
	t2.amt_age_bracket4, 
	t2.amt_age_bracket5, 
	t2.amt_age_bracket6,   
	t2.amt_on_acct,
	t2.amt_balance,
	date_age = t2.last_age_upd_date,
	
        
     
	 t2.date_last_inv, 
	 t2.date_last_cm, 
	 t2.date_last_pyt, 
	 t2.date_last_nsf, 
	 t2.date_last_adj,
	 t2.date_last_fin_chg, 
	 t2.date_last_wr_off, 
	 t2.date_last_late_chg,
	 t2.date_last_comm,
  	 t2.high_date_ar,
	 t2.high_date_inv,

	 
	 t2.amt_last_inv, 
	 t2.amt_last_cm, 
	 t2.amt_last_pyt,
	 t2.amt_last_nsf, 
	 t2.amt_last_adj,
	 t2.amt_last_fin_chg, 
	 t2.amt_last_wr_off,   
	 t2.amt_last_late_chg,
	 t2.amt_last_comm,
 	 t2.high_amt_ar,
	 t2.high_amt_inv,
 
	 
	 t2.last_inv_doc, 
	 t2.last_cm_doc, 
	 t2.last_pyt_doc,
	 t2.last_nsf_doc, 
	 t2.last_adj_doc,
	 t2.last_fin_chg_doc, 
	 t2.last_wr_off_doc,
	 t2.last_late_chg_doc,
     
     
     t2.last_inv_cur,
     t2.last_cm_cur,
     t2.last_adj_cur,
     t2.last_wr_off_cur,
     t2.last_pyt_cur,
     t2.last_nsf_cur,
     t2.last_fin_chg_cur,
     t2.last_late_chg_cur,
	shipped_flag = 'Yes',	
				
				  
				

	x_amt_on_order=t2.amt_on_order, 
	x_amt_inv_unposted=t2.amt_inv_unposted, 
	x_num_inv=t2.num_inv,
	x_num_inv_paid=t2.num_inv_paid,
	x_num_overdue_pyt=t2.num_overdue_pyt,
	x_avg_days_pay=t2.avg_days_pay,
	x_avg_days_overdue=t2.avg_days_overdue, 
	
	
	x_amt_age_bracket1=t2.amt_age_bracket1, 
	x_amt_age_bracket2=t2.amt_age_bracket2, 
	x_amt_age_bracket3=t2.amt_age_bracket3,
	x_amt_age_bracket4=t2.amt_age_bracket4, 
	x_amt_age_bracket5=t2.amt_age_bracket5, 
	x_amt_age_bracket6=t2.amt_age_bracket6, 
	x_amt_on_acct=t2.amt_on_acct,
	x_amt_balance=t2.amt_balance,
	x_date_age = t2.last_age_upd_date,
	
  
 
	 x_date_last_inv=t2.date_last_inv, 
	 x_date_last_cm=t2.date_last_cm, 
	 x_date_last_pyt=t2.date_last_pyt, 
	 x_date_last_nsf=t2.date_last_nsf, 
	 x_date_last_adj=t2.date_last_adj,
	 x_date_last_fin_chg=t2.date_last_fin_chg, 
	 x_date_last_wr_off=t2.date_last_wr_off, 
	 x_date_last_late_chg=t2.date_last_late_chg,
	 x_date_last_comm=t2.date_last_comm,
 	 x_high_date_ar=t2.high_date_ar,
	 x_high_date_inv=t2.high_date_inv,

	 
	 x_amt_last_inv=t2.amt_last_inv, 
	 x_amt_last_cm=t2.amt_last_cm, 
	 x_amt_last_pyt=t2.amt_last_pyt,
	 x_amt_last_nsf=t2.amt_last_nsf, 
	 x_amt_last_adj=t2.amt_last_adj,
	 x_amt_last_fin_chg=t2.amt_last_fin_chg, 
	 x_amt_last_wr_off=t2.amt_last_wr_off, 
	 x_amt_last_late_chg=t2.amt_last_late_chg,
	 x_amt_last_comm=t2.amt_last_comm,
 	 x_high_amt_ar=t2.high_amt_ar,
	 x_high_amt_inv=t2.high_amt_inv

     
  FROM 
  	armaster t1
  		LEFT OUTER JOIN aractcus t2 ON (t1.customer_code = t2.customer_code)  
  WHERE t1.address_type = 0
GO
GRANT REFERENCES ON  [dbo].[arcu1_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcu1_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcu1_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcu1_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcu1_vw] TO [public]
GO
