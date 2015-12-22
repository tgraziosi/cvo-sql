SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_ALLInvoiceDetails_vw]
AS
	SELECT  ar.timestamp,		ar.trx_ctrl_num,	ar.org_id,				ar.doc_ctrl_num,		ar.sequence_id,
			ar.location_code,	ar.item_code,		ar.line_desc,			ar.qty_ordered,
			ar.qty_shipped,		ar.unit_code,		ar.unit_price,			ar.tax_code,
			ar.gl_rev_acct,		ar.discount_prc,	ar.extended_price,		ar.discount_amt
		FROM artrxcdt ar
	UNION
	SELECT  ar.timestamp,		ar.trx_ctrl_num,	ar.org_id,				ar.doc_ctrl_num,		ar.sequence_id,
			ar.location_code,	ar.item_code,		ar.line_desc,			ar.qty_ordered,
			ar.qty_shipped,		ar.unit_code,		ar.unit_price,			ar.tax_code,
			ar.gl_rev_acct,		ar.discount_prc,	ar.extended_price,		ar.discount_amt
		FROM arinpcdt ar
GO
GRANT SELECT ON  [dbo].[ar_ALLInvoiceDetails_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_ALLInvoiceDetails_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_ALLInvoiceDetails_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_ALLInvoiceDetails_vw] TO [public]
GO
