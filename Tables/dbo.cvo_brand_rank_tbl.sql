CREATE TABLE [dbo].[cvo_brand_rank_tbl]
(
[rel_date] [datetime] NULL,
[pom_date] [datetime] NULL,
[brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MODEL] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[num_releases] [int] NULL,
[num_cust] [int] NULL,
[num_cust_wk4] [int] NULL,
[num_cust_wk6] [int] NULL,
[net_qty] [real] NULL,
[st_qty] [real] NULL,
[rx_qty] [real] NULL,
[return_qty] [real] NULL,
[sales_qty] [real] NULL,
[ret_pct] [real] NULL,
[rx_pct] [real] NULL,
[Promo_pct_m1_3] [real] NULL,
[eye_shape] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Material] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PrimaryDemographic] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Frame_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ASOFDATE] [datetime] NULL,
[quartile] [int] NULL,
[id] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_brand_rank_model] ON [dbo].[cvo_brand_rank_tbl] ([brand], [MODEL]) INCLUDE ([ASOFDATE], [quartile]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [idx_brand_rank_id] ON [dbo].[cvo_brand_rank_tbl] ([id]) ON [PRIMARY]
GO
