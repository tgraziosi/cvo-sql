CREATE TABLE [dbo].[cvo_cmi_brands]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[brand_key] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[brand_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_brands] ADD CONSTRAINT [PK__cvo_cmi_brands__6B231DDB] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
