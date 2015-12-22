CREATE TABLE [dbo].[cvo_vision_expo_confroom]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[room_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[room_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_appts] [smallint] NULL,
[email_address] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_confroom] ADD CONSTRAINT [PK__cvo_vision_expo___531F46DD] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
