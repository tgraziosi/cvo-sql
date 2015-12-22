CREATE TABLE [dbo].[cvo_cmi_attributes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[field_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_values] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[idx] [smallint] NULL,
[added_by] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL CONSTRAINT [DF__cvo_cmi_a__added__090B1A4C] DEFAULT (getdate()),
[modified_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_attributes] ADD CONSTRAINT [PK__cvo_cmi_attribut__0816F613] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ATTR_IDX] ON [dbo].[cvo_cmi_attributes] ([field_name]) ON [PRIMARY]
GO
