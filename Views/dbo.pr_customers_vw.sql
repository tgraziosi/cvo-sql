SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[pr_customers_vw] AS

SELECT 	[contract_ctrl_num], [sequence_id], 'price_class_flag'=0, [customer_code], 'price_class'='', [void], [amount_paid_to_date_home],
	[amount_accrued_home], [amount_paid_to_date_oper], [amount_accrued_oper], [date_entered], [userid], 'source'=0
  FROM	[pr_customers]
UNION
SELECT 	[contract_ctrl_num], [sequence_id], 'price_class_flag'=1, 'customer_code'='', [price_class], [void], [amount_paid_to_date_home],
	[amount_accrued_home], [amount_paid_to_date_oper], [amount_accrued_oper], [date_entered], [userid], 'source'=1
  FROM	[pr_customer_class]

GO
GRANT REFERENCES ON  [dbo].[pr_customers_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_customers_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_customers_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_customers_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_customers_vw] TO [public]
GO
