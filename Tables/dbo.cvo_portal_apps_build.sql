CREATE TABLE [dbo].[cvo_portal_apps_build]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[STATUS] [tinyint] NOT NULL CONSTRAINT [DF__cvo_porta__STATU__4E05BDCF] DEFAULT ('1'),
[APP_NAME] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_porta__APP_N__4EF9E208] DEFAULT (NULL),
[TITLE] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LINK] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ICON] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DETAILS] [varchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[APP_DATE] [datetime] NOT NULL CONSTRAINT [DF__cvo_porta__APP_D__4FEE0641] DEFAULT (getdate()),
[isNew] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cvo_porta__isNew__50E22A7A] DEFAULT ('y')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_portal_apps_build] ADD CONSTRAINT [PK__cvo_portal_apps___4D119996] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
