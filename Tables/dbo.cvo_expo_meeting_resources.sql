CREATE TABLE [dbo].[cvo_expo_meeting_resources]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[resource_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_email] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_note] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_active] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_expo_meeting_resources] ADD CONSTRAINT [PK__cvo_expo_meeting__63F4FEEE] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
