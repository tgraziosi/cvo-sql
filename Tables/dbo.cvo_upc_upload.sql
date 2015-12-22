CREATE TABLE [dbo].[cvo_upc_upload]
(
[upc_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
