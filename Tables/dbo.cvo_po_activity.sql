CREATE TABLE [dbo].[cvo_po_activity]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[po_no] [int] NULL,
[part_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_due_date] [datetime] NULL,
[po_qty_ship] [int] NULL,
[po_status] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_ship] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_key] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_date] [datetime] NULL,
[activity_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_po_activity] ADD CONSTRAINT [PK__cvo_po_activity__217C64C4] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
