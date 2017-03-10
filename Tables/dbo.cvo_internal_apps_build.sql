CREATE TABLE [dbo].[cvo_internal_apps_build]
(
[ID] [int] NOT NULL IDENTITY(0, 1),
[STATUS] [tinyint] NOT NULL CONSTRAINT [DF__cvo_inter__STATU__644A04A9] DEFAULT ('1'),
[APP_PRIV] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_inter__APP_P__653E28E2] DEFAULT (NULL),
[TITLE] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LINK] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ICON] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DETAILS] [varchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[APP_DATE] [datetime] NOT NULL CONSTRAINT [DF__cvo_inter__APP_D__66324D1B] DEFAULT (getdate()),
[isNew] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cvo_inter__isNew__67267154] DEFAULT ('y')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_internal_apps_build] ADD CONSTRAINT [PK__cvo_internal_app__6355E070] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
