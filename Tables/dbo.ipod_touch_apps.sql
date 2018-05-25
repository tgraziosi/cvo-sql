CREATE TABLE [dbo].[ipod_touch_apps]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[link] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[icon] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[size] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
