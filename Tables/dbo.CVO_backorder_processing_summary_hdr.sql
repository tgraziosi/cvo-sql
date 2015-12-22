CREATE TABLE [dbo].[CVO_backorder_processing_summary_hdr]
(
[template_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[total_backorders] [decimal] (20, 8) NULL,
[rx_backorders] [decimal] (20, 8) NULL,
[st_backorders] [decimal] (20, 8) NULL,
[total_allocated] [decimal] (20, 8) NULL,
[rx_allocated] [decimal] (20, 8) NULL,
[st_allocated] [decimal] (20, 8) NULL,
[xfer_backorders] [decimal] (20, 8) NULL,
[xfer_allocated] [decimal] (20, 8) NULL,
[has_assignments] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_backorder_processing_summary_hdr_pk] ON [dbo].[CVO_backorder_processing_summary_hdr] ([template_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_summary_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_summary_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_summary_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_summary_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_summary_hdr] TO [public]
GO
