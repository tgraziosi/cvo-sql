SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* arcbs - ERA7.0B.3 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 2000 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 2000 The Emerald Group, Inc. , 2000  
                 All Rights Reserved                    
*/                                                


create view [dbo].[arcb_vw] as

select	
	m.address_name,
	x.customer_code,
	x.doc_ctrl_num,
	x.trx_ctrl_num,
	past_due_status=case CONVERT(int,SIGN(1 + SIGN(datediff(dd,"1/1/80",getdate())+722815 - x.date_due))* SIGN(1 - x.paid_flag))
		when 0 then 'No'
		when 1 then 'Yes'
	end,
	settled_status= case x.paid_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
	c.cb_status_code,
        c.cb_reason_code,
        c.cb_reason_desc,
        c.cb_responsibility_code,
        c.store_number,
	x.nat_cur_code,
	amt_net=x.amt_tot_chg,
	x.amt_paid_to_date,
	unpaid_balance=x.amt_tot_chg - x.amt_paid_to_date,
	amt_past_due=(x.amt_tot_chg - x.amt_paid_to_date)*(SIGN(1 + SIGN(datediff(dd,"1/1/80",getdate())+722815 - x.date_due))* SIGN(1 - x.paid_flag)),
	x.date_doc,
	x.date_applied,
	x.date_due,
	last_payment_date=x.date_paid,
	x.gl_trx_id,
	trx_type = x.apply_trx_type,
	trx_desc = 'CHGBACK',
	x.org_id
from	artrx x, armaster m, arcbinv c
where	x.customer_code = m.customer_code
and	m.address_type = 0
and	x.doc_ctrl_num = x.apply_to_num
and	x.trx_type = x.apply_trx_type
and	x.trx_type <= 2031
and	x.trx_ctrl_num = c.trx_ctrl_num


/**/ 
                                        
GO
GRANT REFERENCES ON  [dbo].[arcb_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcb_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcb_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcb_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcb_vw] TO [public]
GO
