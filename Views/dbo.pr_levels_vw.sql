SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[pr_levels_vw] AS

SELECT [contract_ctrl_num], 'part_class_flag'=0, [part_no], 'part_category'='', [level], [from_range], [to_range], [rebate], [date_entered], [userid], 'source'=0
  FROM [pr_part_levels]
UNION
SELECT [contract_ctrl_num], 'part_class_flag'=1, 'part_no'='', [part_category], [level], [from_range], [to_range], [rebate], [date_entered], [userid], 'source'=1
  FROM [pr_category_levels]
GO
GRANT REFERENCES ON  [dbo].[pr_levels_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_levels_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_levels_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_levels_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_levels_vw] TO [public]
GO
