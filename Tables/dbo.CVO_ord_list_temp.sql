CREATE TABLE [dbo].[CVO_ord_list_temp]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ordered] [decimal] (20, 8) NULL,
[is_pop_gif] [int] NULL CONSTRAINT [DF__CVO_ord_l__is_po__336E006A] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_CVO_ord_list_temp] ON [dbo].[CVO_ord_list_temp] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_ord_list_temp] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_ord_list_temp] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ord_list_temp] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ord_list_temp] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ord_list_temp] TO [public]
GO
