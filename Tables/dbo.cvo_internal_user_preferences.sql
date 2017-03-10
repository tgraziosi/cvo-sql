CREATE TABLE [dbo].[cvo_internal_user_preferences]
(
[ID] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LAYOUT_ORDER] [varchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_internal_user_preferences] ADD CONSTRAINT [PK__cvo_internal_use__6A02DDFF] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
