CREATE TABLE [dbo].[cvo_upc_SCANDATA_tmp]
(
[UPC_CODE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[datetime] [datetime] NULL,
[fct] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QTY] [int] NULL,
[ID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_upc_SCANDATA_tmp] ADD CONSTRAINT [PK__cvo_upc_SCANDATA__150F67D0] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
