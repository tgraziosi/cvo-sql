SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_ALLCreditMemos_vw]
AS
	SELECT  ar.timestamp,ar.trx_ctrl_num,	ar.org_id,				ar.customer_code,		armaster_all.address_name AS customer_name,		
			ar.doc_ctrl_num,				ar.ship_to_code,		ar.void_flag,			ar.posted_flag,
			0 AS hold_flag,					ar.nat_cur_code,		ar.date_doc,			ar.date_applied,
			ar.gl_trx_id,					ar.amt_gross,			ar.amt_freight,			ar.amt_tax,
			ar.amt_tax_included,			ar.amt_discount,		ar.amt_net,				0 as amt_paid,
			0 as amt_due,					ar.amt_cost,			0 as amt_profit,		ar.amt_paid_to_date,
			ar.amt_on_acct,					ar.amt_tot_chg,			ar.apply_trx_type,		ar.order_ctrl_num,
			ar.trx_type,					ar.user_id	
		FROM artrx ar
			LEFT OUTER JOIN armaster_all ON armaster_all.customer_code = ar.customer_code 
		WHERE ar.trx_type = 2032
UNION
	SELECT  ar.timestamp,ar.trx_ctrl_num,	ar.org_id,				ar.customer_code,		armaster_all.address_name AS customer_name,		
			ar.doc_ctrl_num,				ar.ship_to_code,		0 as void_flag,			ar.posted_flag,
			ar.hold_flag,					ar.nat_cur_code,		ar.date_doc,			ar.date_applied,
			'' as gl_trx_id,				ar.amt_gross,			ar.amt_freight,			ar.amt_tax,
			ar.amt_tax_included,			ar.amt_discount,		ar.amt_net,				ar.amt_paid,
			ar.amt_due,						ar.amt_cost,			ar.amt_profit,			0 as amt_paid_to_date,
			0 as amt_on_acct,				0 as amt_tot_chg,		ar.apply_trx_type,		ar.order_ctrl_num,
			ar.trx_type,					ar.user_id		
		FROM arinpchg ar
			LEFT OUTER JOIN armaster_all ON armaster_all.customer_code = ar.customer_code 
		WHERE ar.trx_type = 2032 and ar.printed_flag = 1
GO
GRANT SELECT ON  [dbo].[ar_ALLCreditMemos_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_ALLCreditMemos_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_ALLCreditMemos_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_ALLCreditMemos_vw] TO [public]
GO
