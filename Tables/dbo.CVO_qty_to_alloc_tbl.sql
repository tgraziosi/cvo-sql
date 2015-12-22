CREATE TABLE [dbo].[CVO_qty_to_alloc_tbl]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_line_no] [int] NULL,
[line_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_to_alloc] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_qty_to_alloc_ind_tag] ON [dbo].[CVO_qty_to_alloc_tbl] ([location], [order_no], [order_ext], [from_line_no], [line_no], [qty_to_alloc]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_qty_to_alloc_tbl_ind0] ON [dbo].[CVO_qty_to_alloc_tbl] ([order_no], [order_ext], [line_no], [from_line_no], [location], [part_no]) ON [PRIMARY]
GO
GRANT CONTROL ON  [dbo].[CVO_qty_to_alloc_tbl] TO [public] WITH GRANT OPTION
GO
GRANT SELECT ON  [dbo].[CVO_qty_to_alloc_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_qty_to_alloc_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_qty_to_alloc_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_qty_to_alloc_tbl] TO [public]
GO
