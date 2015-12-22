CREATE TABLE [dbo].[cvo_auto_alloc_past_orders_templates]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[order_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[alloc_order] [smallint] NOT NULL,
[template_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[where_clause] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_auto_alloc_past_orders_templates_inx01] ON [dbo].[cvo_auto_alloc_past_orders_templates] ([order_type]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_auto_alloc_past_orders_templates_pk] ON [dbo].[cvo_auto_alloc_past_orders_templates] ([rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_auto_alloc_past_orders_templates] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_auto_alloc_past_orders_templates] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_auto_alloc_past_orders_templates] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_auto_alloc_past_orders_templates] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_auto_alloc_past_orders_templates] TO [public]
GO
