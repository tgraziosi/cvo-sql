CREATE TABLE [dbo].[cvo_docs_files]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[name] [varchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[notes] [varchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[keywords] [varchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expire_date] [smalldatetime] NOT NULL,
[cat_id] [int] NOT NULL,
[dept_id] [int] NOT NULL,
[type] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_active] [int] NULL CONSTRAINT [defaultActiveState] DEFAULT ('1')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_docs_files] ADD CONSTRAINT [PK__cvo_docs_files__500B9FCD] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_docs_files] ADD CONSTRAINT [UQ__cvo_docs_files__716C9398] UNIQUE NONCLUSTERED  ([name], [dept_id]) ON [PRIMARY]
GO
