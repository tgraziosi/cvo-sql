CREATE TABLE [dbo].[CVO_backorder_processing_allocation_issues]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[rec_date] [datetime] NOT NULL,
[template_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[is_transfer] [smallint] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_reqd] [decimal] (20, 8) NOT NULL,
[qty_allocated] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_backorder_processing_allocation_issues_pk] ON [dbo].[CVO_backorder_processing_allocation_issues] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_allocation_issues_inx01] ON [dbo].[CVO_backorder_processing_allocation_issues] ([template_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_allocation_issues] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_allocation_issues] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_allocation_issues] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_allocation_issues] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_allocation_issues] TO [public]
GO
