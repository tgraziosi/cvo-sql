SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[CVO_Voucher_vw]
AS
SELECT     
	apvo2_vw.voucher_no, 
	CVO_APVO1_VW.INVOICE_NO, 
	CVO_APVO1_VW.VENDOR_CODE, 
	CVO_APVO1_VW.ADDRESS_NAME, 
	CVO_APVO1_VW.DATE_DOC, 
	CVO_APVO1_VW.DATE_APPLIED, 
	CVO_APVO1_VW.DATE_DUE, 
	CVO_APVO1_VW.POSTED_FLAG, 
	CVO_APVO1_VW.HOLD_FLAG, 
	CVO_APVO1_VW.AMT_NET, 
	CVO_APVO1_VW.AMT_PAID, 
	apvo2_vw.sequence_id, 
	apvo2_vw.item_code, 
	apvo2_vw.line_desc, 
	apvo2_vw.qty_ordered, 
	apvo2_vw.qty_received, 
	apvo2_vw.unit_price, 
	apvo2_vw.amt_extended, 
	CVO_APVO1_VW.X_AMT_NET, 
	CVO_APVO1_VW.X_AMT_PAID, 
	CVO_APVO1_VW.X_AMT_OPEN, 
	CVO_APVO1_VW.X_DATE_DOC, 
	CVO_APVO1_VW.X_DATE_DUE, 
	CVO_APVO1_VW.X_DATE_DISCOUNT, 
	apvo2_vw.x_qty_ordered, 
	apvo2_vw.x_qty_received, 
	apvo2_vw.x_unit_price, 
	apvo2_vw.x_amt_discount, 
	apvo2_vw.x_amt_freight, 
	apvo2_vw.x_amt_tax, 
	apvo2_vw.x_amt_misc, 
	apvo2_vw.x_amt_extended, 
	apvo2_vw.x_date_applied
FROM
	CVO_APVO1_VW INNER JOIN
	apvo2_vw ON CVO_APVO1_VW.VENDOR_CODE = apvo2_vw.vendor_code 
	AND CVO_APVO1_VW.VOUCHER_NO = apvo2_vw.voucher_no



GO
GRANT SELECT ON  [dbo].[CVO_Voucher_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_Voucher_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_Voucher_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_Voucher_vw] TO [public]
GO
