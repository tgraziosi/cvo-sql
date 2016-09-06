CREATE TABLE [dbo].[cvo_docs_category]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[name] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[department_id] [int] NOT NULL,
[is_active] [int] NULL CONSTRAINT [defaultActiveState_cat] DEFAULT ('1')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_docs_category] ADD CONSTRAINT [PK__cvo_docs_categor__4B46EAB0] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_docs_category] ADD CONSTRAINT [UQ__cvo_docs_categor__57ACC195] UNIQUE NONCLUSTERED  ([name], [department_id]) ON [PRIMARY]
GO
