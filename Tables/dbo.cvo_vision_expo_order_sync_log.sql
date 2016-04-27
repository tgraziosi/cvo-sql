CREATE TABLE [dbo].[cvo_vision_expo_order_sync_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[log_message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[log_time] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_order_sync_log] ADD CONSTRAINT [PK__cvo_vision_expo___2417439F] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
