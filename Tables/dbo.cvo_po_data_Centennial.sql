CREATE TABLE [dbo].[cvo_po_data_Centennial]
(
[PO_Data] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_id] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_po_data_Centennial] ADD CONSTRAINT [PK_cvo_po_data_Centennial] PRIMARY KEY CLUSTERED  ([rec_id]) ON [PRIMARY]
GO
