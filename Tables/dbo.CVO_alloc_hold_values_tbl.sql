CREATE TABLE [dbo].[CVO_alloc_hold_values_tbl]
(
[hold_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT CONTROL ON  [dbo].[CVO_alloc_hold_values_tbl] TO [public] WITH GRANT OPTION
GO
GRANT SELECT ON  [dbo].[CVO_alloc_hold_values_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_alloc_hold_values_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_alloc_hold_values_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_alloc_hold_values_tbl] TO [public]
GO
