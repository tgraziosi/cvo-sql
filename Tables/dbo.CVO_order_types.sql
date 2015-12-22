CREATE TABLE [dbo].[CVO_order_types]
(
[order_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_eligible] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_order_types] ON [dbo].[CVO_order_types] ([order_category]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_order_types] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_order_types] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_order_types] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_order_types] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_order_types] TO [public]
GO
