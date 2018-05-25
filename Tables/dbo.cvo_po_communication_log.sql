CREATE TABLE [dbo].[cvo_po_communication_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[vendor_id] [int] NULL,
[brand] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[ws_id] [int] NULL,
[entity] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entity_user] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[event_category] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_date] [datetime] NULL,
[comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_po_communication_log] ADD CONSTRAINT [PK__cvo_po_communica__11B0114F] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
