CREATE TABLE [dbo].[cvo_vision_expo_east_config]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_zone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expo_start] [datetime] NULL,
[expo_end] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_east_config] ADD CONSTRAINT [PK__cvo_vision_expo___29C52FFD] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
