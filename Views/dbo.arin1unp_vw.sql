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





CREATE view [dbo].[arin1unp_vw] as

SELECT 
	m.address_name,
	x.customer_code,
	m.state as state_code,					--v1.0
	x.doc_ctrl_num,
	x.trx_ctrl_num,
	x.org_id,
	past_due_status=case CONVERT(int,SIGN(1 + SIGN(datediff(dd,"1/1/80",getdate())+722815 - x.date_due))* SIGN(1 - (SIGN(1 - SIGN(x.amt_net - x.amt_paid)))))
		when 0 then 'No'
		when 1 then 'Yes'
	end,
	settled_status=case CONVERT(int,SIGN(1 - SIGN(x.amt_net - x.amt_paid)))
		when 0 then 'No'
		when 1 then 'Yes'
	end,
	hold_flag = case x.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
	posted_flag='No',
	x.nat_cur_code,
	x.amt_net,
	x.amt_freight,--dmoon SOW Mod 05/25/2010
	x.amt_tax,--dmoon SOW Mod 05/25/2010
	amt_paid_to_date=x.amt_paid,
	unpaid_balance=x.amt_net - x.amt_paid,
	amt_past_due=(x.amt_net - x.amt_paid)*(SIGN(1 + SIGN(datediff(dd,"1/1/80",getdate())+722815 - x.date_due))* SIGN(1 - (SIGN(1 - SIGN(x.amt_net - x.amt_paid))))),
    x.terms_code, -- tag 020414 - lm request	
	x.date_doc,
	x.date_applied,
	x.date_due,
	x.date_shipped,
	last_payment_date=0,
	x.cust_po_num,
	x.order_ctrl_num,
	gl_trx_id="",
	x.trx_type,
	trx_desc = case x.trx_type
		when 2021 then 'ATF INV'
		when 2031 then 'Invoice' 
	end
	,dbo.f_cvo_get_buying_group(m.customer_code,
	convert(varchar,dateadd(d,x.DATE_APPLIED-711858,'1/1/1950'),101) ) as Buying_Group

from	arinpchg x (nolock) join armaster m (nolock) on x.customer_code = m.customer_code
where	m.address_type = 0 and	x.trx_type <= 2031


/**/     





GO
GRANT REFERENCES ON  [dbo].[arin1unp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arin1unp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arin1unp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arin1unp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arin1unp_vw] TO [public]
GO
