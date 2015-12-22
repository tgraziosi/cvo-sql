CREATE TABLE [dbo].[CVO_no_stock_linked_pick_trans]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[parent_tran_id] [int] NOT NULL,
[tran_id] [int] NOT NULL,
[create_date] [datetime] NOT NULL,
[create_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_no_stock_linked_pick_trans_inx01] ON [dbo].[CVO_no_stock_linked_pick_trans] ([parent_tran_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_no_stock_linked_pick_trans_pk] ON [dbo].[CVO_no_stock_linked_pick_trans] ([rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_no_stock_linked_pick_trans] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_no_stock_linked_pick_trans] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_no_stock_linked_pick_trans] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_no_stock_linked_pick_trans] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_no_stock_linked_pick_trans] TO [public]
GO
