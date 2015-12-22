SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_ALLCashReceipt_vw]
AS
	SELECT 	ar.timestamp,		ar.trx_ctrl_num,		ar.org_id,					ar.customer_code,	armaster_all.address_name AS customer_name, 
			ar.doc_ctrl_num,	ar.gl_acct_code,		'' AS void_type,			0 AS hold_flag,		ar.trx_type,
			1 AS posted_flag,	ar.nat_cur_code,		ar.amt_net AS amt_payment,	ar.amt_on_acct,		ar.user_id,
			ar.date_entered,	ar.date_applied,		ar.deposit_num,				ar.payment_code,
			ar.date_posted,		ar.gl_trx_id,			ar.cash_acct_code
			FROM artrx ar
				LEFT OUTER JOIN armaster_all ON armaster_all.customer_code = ar.customer_code 
			WHERE trx_type = 2111
	UNION
	SELECT 	ar.timestamp,		ar.trx_ctrl_num,		ar.org_id,				ar.customer_code,		armaster_all.address_name AS customer_name, 
			ar.doc_ctrl_num,	ar.gl_acct_code,		ar.void_type,			ar.hold_flag,			ar.trx_type,
			ar.posted_flag,		ar.nat_cur_code,		ar.amt_payment,			ar.amt_on_acct,			ar.user_id,
			ar.date_entered,	ar.date_applied,		ar.deposit_num,			ar.payment_code,
			'' AS date_posted,	'' AS gl_trx_id,		ar.cash_acct_code
			FROM arinppyt ar 
				LEFT OUTER JOIN armaster_all ON armaster_all.customer_code = ar.customer_code 
			WHERE trx_type = 2111
GO
GRANT SELECT ON  [dbo].[ar_ALLCashReceipt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_ALLCashReceipt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_ALLCashReceipt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_ALLCashReceipt_vw] TO [public]
GO
