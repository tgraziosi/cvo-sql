CREATE TABLE [dbo].[cvo_cmi_worksheet_lead_data]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[ws_id] [int] NULL,
[revision_id] [int] NULL,
[color] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[size] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_demand] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_worksheet_lead_data] ADD CONSTRAINT [PK__cvo_cmi_workshee__2DFFA36B] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
