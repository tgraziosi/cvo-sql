CREATE TABLE [dbo].[cvo_rad_brand]
(
[brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[door] [int] NULL,
[date_opened] [datetime] NULL,
[X_MONTH] [int] NULL,
[year] [int] NULL,
[yyyymmdd] [datetime] NULL,
[netsales] [float] NULL,
[asales] [float] NULL,
[asales_rx] [float] NULL,
[asales_st] [float] NULL,
[areturns] [float] NULL,
[aret_rx] [float] NULL,
[aret_st] [float] NULL,
[areturns_s] [float] NULL,
[aret_rx_s] [float] NULL,
[aret_st_s] [float] NULL,
[rolling12net] [float] NULL,
[rolling12rx] [float] NULL,
[rolling12st] [float] NULL,
[rolling12ret] [float] NULL,
[rolling12ret_s] [float] NULL,
[Rolling12RR] [float] NULL,
[IsActiveDoor] [int] NULL,
[IsNew] [int] NULL,
[qsales] [int] NULL,
[qsales_rx] [int] NULL,
[qsales_st] [int] NULL,
[qreturns] [int] NULL,
[qret_rx] [int] NULL,
[qret_st] [int] NULL,
[qnet_frames] [int] NULL,
[qnet_parts] [int] NULL,
[qnet_cl] [int] NULL,
[anet_cl] [float] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_rad_brand] ON [dbo].[cvo_rad_brand] ([brand], [territory], [customer], [ship_to], [X_MONTH], [year], [yyyymmdd]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_yyyymmdd_rad] ON [dbo].[cvo_rad_brand] ([yyyymmdd]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_rad_brand] TO [public]
GO
