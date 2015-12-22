SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ap_ALLDebitMemoDetails_vw]
AS
	SELECT 	timestamp,		trx_ctrl_num,	org_id,				sequence_id,		location_code,
			item_code,		line_desc,		rec_company_code,	qty_received,		tax_code,
			qty_returned,	unit_code,		unit_price,			amt_extended,		gl_exp_acct,
			amt_discount	
		FROM apdmdet 
	UNION
	SELECT  timestamp,		trx_ctrl_num,	org_id,				sequence_id,		location_code,
			item_code,		line_desc,		rec_company_code,	qty_received,		tax_code,
			qty_returned,	unit_code,		unit_price,			amt_extended,		gl_exp_acct,
			amt_discount
		FROM apinpcdt 
GO
GRANT SELECT ON  [dbo].[ap_ALLDebitMemoDetails_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ap_ALLDebitMemoDetails_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ap_ALLDebitMemoDetails_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ap_ALLDebitMemoDetails_vw] TO [public]
GO
