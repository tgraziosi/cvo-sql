SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ar_dunning_inv_vw]  ( invoice_num, nat_cur_code, apply_to, customer_code, 
 salesperson_code, date_due, amt_due, amt_extra,  amt_paid, amt_unpaid ) AS  SELECT DISTINCT 
 artrxage.doc_ctrl_num,  artrxage.nat_cur_code,  artrxage.apply_to_num,  artrxage.customer_code, 
 artrxage.salesperson_code,  artrxage.date_due,  artrxage.amount,  artrxage.amt_fin_chg + artrxage.amt_late_chg, 
 artrxage.amt_paid,  artrxage.amount - artrxage.amt_paid  FROM artrx, arcust, artrxage 
 WHERE artrx.doc_ctrl_num = artrxage.doc_ctrl_num  AND arcust.customer_code = artrx.customer_code 
 AND arcust.customer_code = artrxage.customer_code  AND arcust.dunning_group_id <> '' 
 AND artrxage.trx_type = 2031  AND artrx.paid_flag = 0  AND artrx.void_flag = 0 
GO
GRANT REFERENCES ON  [dbo].[ar_dunning_inv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ar_dunning_inv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_dunning_inv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_dunning_inv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_dunning_inv_vw] TO [public]
GO
