SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ap_ALLVouchersDetails_vw]
AS
	SELECT 	timestamp,			trx_ctrl_num,		org_id,				sequence_id,		location_code,
			item_code,			line_desc,			qty_ordered,		qty_received,
			unit_code,			unit_price,			amt_extended,		amt_discount,
			amt_freight,		tax_code,			gl_exp_acct,		reference_code,
			code_1099,			amt_misc,			amt_tax,			rec_company_code 
		FROM apvodet 
	UNION
	SELECT 	timestamp,			trx_ctrl_num,		org_id,				sequence_id,		location_code,
			item_code,			line_desc,			qty_ordered,		qty_received,
			unit_code,			unit_price,			amt_extended,		amt_discount,
			amt_freight,		tax_code,			gl_exp_acct,		reference_code,
			code_1099,			amt_misc,			amt_tax,			rec_company_code  
		FROM apinpcdt 
GO
GRANT SELECT ON  [dbo].[ap_ALLVouchersDetails_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ap_ALLVouchersDetails_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ap_ALLVouchersDetails_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ap_ALLVouchersDetails_vw] TO [public]
GO
