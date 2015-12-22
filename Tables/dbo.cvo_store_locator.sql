CREATE TABLE [dbo].[cvo_store_locator]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zipcode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lat] [float] NULL,
[lng] [float] NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_store_locator] ADD CONSTRAINT [PK__cvo_store_locato__539F3521] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
