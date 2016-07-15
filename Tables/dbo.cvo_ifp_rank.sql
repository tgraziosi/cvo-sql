CREATE TABLE [dbo].[cvo_ifp_rank]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[res_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_date] [datetime] NULL,
[pom_date] [datetime] NULL,
[m3_net] [float] NULL,
[m2_net] [float] NULL,
[m1_net] [float] NULL,
[net_qty] [float] NULL,
[months_of_sales] [int] NULL,
[TIER] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDER_THRU_DATE] [datetime] NULL,
[last_upd_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_ifp_rank] ON [dbo].[cvo_ifp_rank] ([id]) ON [PRIMARY]
GO
