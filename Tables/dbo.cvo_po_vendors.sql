CREATE TABLE [dbo].[cvo_po_vendors]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[supplier] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supplier_country] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_po_vendors] ADD CONSTRAINT [PK__cvo_po_suppliers__0FC7C8DD] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
