SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[pr_parts_vw] AS

SELECT	[contract_ctrl_num], [sequence_id], 'part_class_flag'=0, [part_no], 'part_category'='', [void], [amount_paid_to_date_home], 
	[amount_accrued_home], [amount_paid_to_date_oper], [amount_accrued_oper], [percent_flag], 
	[date_entered], [userid], 'source'=0
  FROM 	[pr_parts]
UNION
SELECT	[contract_ctrl_num], [sequence_id], 'part_class_flag'=1, 'part_no'='', [part_category], [void], [amount_paid_to_date_home], 
	[amount_accrued_home], [amount_paid_to_date_oper], [amount_accrued_oper], [percent_flag], 
	[date_entered], [userid], 'source'=1
  FROM 	[pr_part_category]
GO
GRANT REFERENCES ON  [dbo].[pr_parts_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_parts_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_parts_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_parts_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_parts_vw] TO [public]
GO
