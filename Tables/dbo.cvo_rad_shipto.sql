CREATE TABLE [dbo].[cvo_rad_shipto]
(
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
[IsActiveDoor] [int] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_rad_shipto] TO [public]
GO
