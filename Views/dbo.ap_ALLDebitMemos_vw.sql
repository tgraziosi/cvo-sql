SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ap_ALLDebitMemos_vw]
AS
	SELECT  ap.timestamp,		ap.trx_ctrl_num,					ap.doc_ctrl_num,			ap.vendor_code,			apmaster_all.address_name,
			ap.org_id,			ap.apply_to_num,					ap.po_ctrl_num,				1 AS posted_flag,		4092 as trx_type,
			0 AS hold_flag,		ap.currency_code AS nat_cur_code,	ap.amt_gross,				ap.date_doc,			ap.user_id,
			ap.date_applied,	ap.intercompany_flag,				ap.journal_ctrl_num,		ap.tax_code,			ap.amt_net
			FROM apdmhdr ap
				LEFT OUTER JOIN apmaster_all ON apmaster_all.vendor_code = ap.vendor_code 
	UNION
	SELECT	ap.timestamp,			ap.trx_ctrl_num,			ap.doc_ctrl_num,			ap.vendor_code,			apmaster_all.address_name,	
			ap.org_id,				ap.apply_to_num,			ap.po_ctrl_num,				ap.posted_flag,			ap.trx_type,
			ap.hold_flag,			ap.nat_cur_code,			ap.amt_gross,				ap.date_doc,			ap.user_id,
			ap.date_applied,		ap.intercompany_flag,		'' AS journal_ctrl_num,		ap.tax_code,			ap.amt_net 
			FROM apinpchg ap
				LEFT OUTER JOIN apmaster_all ON apmaster_all.vendor_code = ap.vendor_code 
			WHERE trx_type = 4092
GO
GRANT SELECT ON  [dbo].[ap_ALLDebitMemos_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ap_ALLDebitMemos_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ap_ALLDebitMemos_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ap_ALLDebitMemos_vw] TO [public]
GO
