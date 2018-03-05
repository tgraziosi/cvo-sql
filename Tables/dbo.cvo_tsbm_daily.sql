CREATE TABLE [dbo].[cvo_tsbm_daily]
(
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[otype] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[X_MONTH] [int] NULL,
[month] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[year] [int] NULL,
[asales] [float] NULL,
[areturns] [float] NULL,
[anet] [float] NULL,
[qsales] [float] NULL,
[qreturns] [float] NULL,
[qnet] [float] NULL,
[yyyymmdd] [datetime] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_tsbm_daily] TO [public]
GO
