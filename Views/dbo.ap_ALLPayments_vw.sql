SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ap_ALLPayments_vw]
AS
	SELECT 	ap.timestamp,					ap.trx_ctrl_num,					ap.org_id,				ap.vendor_code,		apmaster_all.address_name as vendor_name,
			ap.doc_ctrl_num,				ap.payment_code,					1 AS posted_flag,		ap.cash_acct_code,	ap.currency_code AS nat_cur_code,	
			ap.amt_net AS amt_payment,		ap.amt_on_acct,						ap.amt_discount AS amt_disc_taken,			ap.user_id,
			ap.date_applied,				ap.date_doc,						ap.void_flag,		    0 AS approval_flag,	4111 as trx_type,
			0 AS hold_flag,					2 AS printed_flag,					ap.journal_ctrl_num,	ap.doc_desc,		ISNULL(cminpdtl.date_cleared, 0) AS date_cleared,
			cleared_flag = case ISNULL(cminpdtl.reconciled_flag,0)
				when 0 then 'NO'
				when 1 then 'YES'
			end
			FROM appyhdr ap
				LEFT OUTER JOIN apmaster_all ON apmaster_all.vendor_code = ap.vendor_code 
				LEFT OUTER JOIN cminpdtl cminpdtl ON ap.trx_ctrl_num = cminpdtl.trx_ctrl_num
	UNION
	SELECT ap.timestamp,				ap.trx_ctrl_num,					ap.org_id,				ap.vendor_code,		apmaster_all.address_name as vendor_name,
			ap.doc_ctrl_num,			ap.payment_code,					ap.posted_flag,			ap.cash_acct_code,
			ap.nat_cur_code,			ap.amt_payment,						ap.amt_on_acct,			ap.amt_disc_taken,		ap.user_id,
			ap.date_applied,			ap.date_doc,						0 as void_flag,			ap.approval_flag,		ap.trx_type,
			ap.hold_flag,				ap.printed_flag,					'' AS journal_ctrl_num,	ap.trx_desc as doc_desc, 0 AS date_cleared,
			cleared_flag = 'NO'
			FROM apinppyt ap
				LEFT OUTER JOIN apmaster_all ON apmaster_all.vendor_code = ap.vendor_code 
GO
GRANT SELECT ON  [dbo].[ap_ALLPayments_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ap_ALLPayments_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ap_ALLPayments_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ap_ALLPayments_vw] TO [public]
GO
