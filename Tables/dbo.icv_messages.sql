CREATE TABLE [dbo].[icv_messages]
(
[response_code] [smallint] NOT NULL,
[provider] [smallint] NOT NULL,
[response_message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message_explanation] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [icv_messages_ind_0] ON [dbo].[icv_messages] ([response_code], [provider]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_messages] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_messages] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_messages] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_messages] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_messages] TO [public]
GO
