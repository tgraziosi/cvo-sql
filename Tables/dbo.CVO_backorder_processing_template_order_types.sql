CREATE TABLE [dbo].[CVO_backorder_processing_template_order_types]
(
[template_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_template_order_types_inx01] ON [dbo].[CVO_backorder_processing_template_order_types] ([template_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_template_order_types] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_template_order_types] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_template_order_types] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_template_order_types] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_template_order_types] TO [public]
GO
