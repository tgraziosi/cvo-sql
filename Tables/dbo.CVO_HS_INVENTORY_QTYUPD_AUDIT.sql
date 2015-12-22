CREATE TABLE [dbo].[CVO_HS_INVENTORY_QTYUPD_AUDIT]
(
[TIMESTAMP] [datetime] NOT NULL,
[SKU] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ItemType] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShelfQty] [decimal] (38, 8) NULL,
[WarningLevel] [int] NOT NULL,
[IsAvailable] [int] NOT NULL,
[RestockDate] [datetime] NULL,
[isSynced] [int] NOT NULL,
[Diff] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OldShelfQty] [decimal] (38, 8) NULL
) ON [PRIMARY]
GO
