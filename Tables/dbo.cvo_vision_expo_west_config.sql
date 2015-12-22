CREATE TABLE [dbo].[cvo_vision_expo_west_config]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_zone] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expo_start] [datetime] NULL,
[expo_end] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_west_config] ADD CONSTRAINT [PK__cvo_vision_expo___3AED59FA] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
