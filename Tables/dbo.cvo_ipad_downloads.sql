CREATE TABLE [dbo].[cvo_ipad_downloads]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[title] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[document] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL CONSTRAINT [DF__cvo_ipad___added__1D2328DF] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_ipad_downloads] ADD CONSTRAINT [PK__cvo_ipad_downloa__2D8E9AD2] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
