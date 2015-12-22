SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[pr_vendors_vw] AS

SELECT 	[contract_ctrl_num], [sequence_id], 'vendor_class_flag'=0, [vendor_code], 'vendor_class'='', [void], [amount_paid_to_date_home],
	[amount_accrued_home], [amount_paid_to_date_oper], [amount_accrued_oper], [date_entered], [userid], 'source'=0
  FROM	[pr_vendors]
UNION
SELECT 	[contract_ctrl_num], [sequence_id], 'vendor_class_flag'=1, 'vendor_code'='', [vendor_class], [void], [amount_paid_to_date_home],
	[amount_accrued_home], [amount_paid_to_date_oper], [amount_accrued_oper], [date_entered], [userid], 'source'=1
  FROM	[pr_vendor_class]

GO
GRANT REFERENCES ON  [dbo].[pr_vendors_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_vendors_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_vendors_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_vendors_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_vendors_vw] TO [public]
GO
