CREATE TABLE [dbo].[CVO_backorder_processing_summary_det]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[template_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_backorders] [decimal] (20, 8) NULL,
[rx_backorders] [decimal] (20, 8) NULL,
[rx_filled] [decimal] (20, 8) NULL,
[st_backorders] [decimal] (20, 8) NULL,
[st_filled] [decimal] (20, 8) NULL,
[is_summary] [smallint] NOT NULL,
[process] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_backorder_processing_summary_det_pk] ON [dbo].[CVO_backorder_processing_summary_det] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_summary_det_inx01] ON [dbo].[CVO_backorder_processing_summary_det] ([template_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_summary_det] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_summary_det] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_summary_det] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_summary_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_summary_det] TO [public]
GO
