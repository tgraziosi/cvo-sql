CREATE TABLE [dbo].[cvo_cmi_tst1]
(
[id] [bigint] NOT NULL IDENTITY(1, 1),
[name] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_tst1] ADD CONSTRAINT [PK__cvo_cmi_tst1__9D0B998D] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
