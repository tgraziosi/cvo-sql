CREATE TABLE [dbo].[cvo_docs_department]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[name] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_docs_department] ADD CONSTRAINT [PK__cvo_docs_departm__4E23575B] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
