SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE view [dbo].[CVO_on_account_payments_vw] 
as

SELECT o.trx_ctrl_num,  
    o.doc_ctrl_num,  
	o.trx_type,
    o.customer_code,
    o.ship_to_code,
    v.address_name,
    o.date_doc,  
    o.date_applied, 
	o.date_due, 
    o.payment_code,  
    o.cash_acct_code,
    o.amt_net*o.rate_oper amt_net,  
    o.amt_on_acct*o.rate_oper amt_on_acct,  
    o.nat_cur_code,   
    o.rate_oper
FROM artrx_all o (nolock) 
join armaster_all v (nolock) on  o.customer_code = v.customer_code and o.ship_to_code = v.ship_to_code
WHERE o.void_flag = 0  
AND ((o.amt_on_acct) > (0.0) + 0.0000001)  
--AND o.payment_type IN (1,3) 
and o.trx_type in 
(2032,2161,2111) 



GO
GRANT REFERENCES ON  [dbo].[CVO_on_account_payments_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_on_account_payments_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_on_account_payments_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_on_account_payments_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_on_account_payments_vw] TO [public]
GO
