CREATE TABLE [dbo].[cvo_hs_inventory_qtyupd_v8]
(
[SKU] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ItemType] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShelfQty] [decimal] (38, 8) NULL,
[WarningLevel] [int] NOT NULL,
[IsAvailable] [int] NOT NULL,
[RestockDate] [datetime] NULL,
[isSynced] [int] NOT NULL,
[Diff] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OldShelfQty] [decimal] (38, 8) NULL,
[date_added] [datetime] NULL,
[date_modified] [datetime] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [idx_hs_inv_upd_prtno] ON [dbo].[cvo_hs_inventory_qtyupd_v8] ([SKU]) ON [PRIMARY]
GO
