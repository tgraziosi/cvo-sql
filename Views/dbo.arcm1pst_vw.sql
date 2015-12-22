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


/** TAG - for CVO - 3/27/2012 - Add order control number to output **/


CREATE view [dbo].[arcm1pst_vw]  as
select 
	t2.address_name,	 
	t2.customer_code,	
	t1.doc_ctrl_num, 	
	t1.org_id,		
	t1.trx_ctrl_num,
	void_flag = case t1.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,		
	posted_flag = case t1.posted_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,		
	hold_flag='No',		
	t1.nat_cur_code,	
	case when recurring_flag=1 then t1.amt_net
         when recurring_flag=2 then t1.amt_tax 
         when recurring_flag=3 then t1.amt_freight
         when recurring_flag=4 then (t1.amt_freight + amt_tax)
         end  as amt_net,		
	recurring_flag = t3.cm_descr,						  
	t1.date_doc, 		
	t1.date_applied,
	t1.date_due, -- 032114 - tag	
	t1.gl_trx_id,
	t1.order_ctrl_num	-- 3/27/2012 - tag - for CVO		
	,dbo.f_cvo_get_buying_group(t2.customer_code,
	convert(varchar,dateadd(d,t1.DATE_APPLIED-711858,'1/1/1950'),101) ) as Buying_Group

  from 
	artrx t1, armaster t2, arcmtype t3
  where (t1.customer_code = t2.customer_code) 
	and t1.trx_type in (2032)	
	and t2.address_type = 0
	and t1.recurring_flag = t3.cm_type



/**/


GO
GRANT REFERENCES ON  [dbo].[arcm1pst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcm1pst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcm1pst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcm1pst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcm1pst_vw] TO [public]
GO
