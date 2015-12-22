CREATE TABLE [dbo].[cvo_csbm_shipto]
(
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[X_MONTH] [int] NULL,
[month] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[year] [int] NULL,
[asales] [float] NULL,
[asales_rx] [float] NULL,
[asales_st] [float] NULL,
[areturns] [float] NULL,
[aret_rx] [float] NULL,
[aret_st] [float] NULL,
[anet] [float] NULL,
[areturns_s] [float] NULL,
[aret_rx_s] [float] NULL,
[aret_st_s] [float] NULL,
[qsales] [float] NULL,
[qsales_rx] [float] NULL,
[qsales_st] [float] NULL,
[qreturns] [float] NULL,
[qret_rx] [float] NULL,
[qret_st] [float] NULL,
[qnet] [float] NULL,
[qreturns_s] [float] NULL,
[qret_rx_s] [float] NULL,
[qret_st_s] [float] NULL,
[yyyymmdd] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_csbm_shipto] ON [dbo].[cvo_csbm_shipto] ([customer], [ship_to], [month], [year], [yyyymmdd]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_csbm_shipto] TO [public]
GO
