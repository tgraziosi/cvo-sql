CREATE TABLE [dbo].[cvo_spv_tbl]
(
[sku] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mastersku] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eff_date] [datetime] NULL,
[obs_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [idx_sku] ON [dbo].[cvo_spv_tbl] ([sku]) ON [PRIMARY]
GO
