CREATE TABLE [dbo].[CVO_backorder_processing_pick_tickets]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[rec_date] [datetime] NOT NULL,
[template_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[is_transfer] [smallint] NOT NULL,
[printed] [smallint] NOT NULL,
[printed_date] [datetime] NULL,
[reason] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_bkord_proc_pick_tick_idx1] ON [dbo].[CVO_backorder_processing_pick_tickets] ([order_no], [ext], [is_transfer], [printed]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_backorder_processing_pick_tickets_pk] ON [dbo].[CVO_backorder_processing_pick_tickets] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_pick_tickets_inx01] ON [dbo].[CVO_backorder_processing_pick_tickets] ([template_code], [printed]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_pick_tickets] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_pick_tickets] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_pick_tickets] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_pick_tickets] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_pick_tickets] TO [public]
GO
