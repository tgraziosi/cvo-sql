CREATE TABLE [dbo].[cvo_backorder_processing_log]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[log_time] [datetime] NOT NULL,
[log_msg] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_backorder_processing_log_pk] ON [dbo].[cvo_backorder_processing_log] ([rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_backorder_processing_log] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_backorder_processing_log] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_backorder_processing_log] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_backorder_processing_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_backorder_processing_log] TO [public]
GO
