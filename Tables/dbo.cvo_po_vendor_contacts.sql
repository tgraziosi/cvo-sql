CREATE TABLE [dbo].[cvo_po_vendor_contacts]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_id] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_po_vendor_contacts] ADD CONSTRAINT [PK__cvo_po_vendor_co__6D4893A7] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
