CREATE TABLE [dbo].[cvo_cmi_worksheet_spares]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[ws_id] [int] NULL,
[revision_id] [int] NULL,
[part_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_qty] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_unit] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_worksheet_spares] ADD CONSTRAINT [PK__cvo_cmi_workshee__2C175AF9] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
