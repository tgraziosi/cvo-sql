CREATE TABLE [dbo].[cvo_po_activity_vendor]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[po_no] [int] NULL,
[part_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_po_due_date] [datetime] NULL,
[vend_po_qty_ship] [int] NULL,
[vend_po_status] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_po_ship] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_po_comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_key] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_activity_date] [datetime] NULL,
[vend_activity_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pend_due_date] [datetime] NULL,
[notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_po_activity_vendor] ADD CONSTRAINT [PK__cvo_po_activity___2364AD36] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
