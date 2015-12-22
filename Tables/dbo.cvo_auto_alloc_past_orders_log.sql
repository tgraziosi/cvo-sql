CREATE TABLE [dbo].[cvo_auto_alloc_past_orders_log]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[log_date] [datetime] NOT NULL,
[order_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[ext] [int] NULL,
[log_msg] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_auto_alloc_past_orders_log_inx01] ON [dbo].[cvo_auto_alloc_past_orders_log] ([order_no], [ext]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_auto_alloc_past_orders_log_pk] ON [dbo].[cvo_auto_alloc_past_orders_log] ([rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_auto_alloc_past_orders_log] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_auto_alloc_past_orders_log] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_auto_alloc_past_orders_log] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_auto_alloc_past_orders_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_auto_alloc_past_orders_log] TO [public]
GO
