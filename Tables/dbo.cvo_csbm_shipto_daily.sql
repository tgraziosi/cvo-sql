CREATE TABLE [dbo].[cvo_csbm_shipto_daily]
(
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE NONCLUSTERED INDEX [idx_cvo_csbm_shipto] ON [dbo].[cvo_csbm_shipto_daily] ([customer], [ship_to], [month], [year], [yyyymmdd]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_csbm_shipto_daily] TO [public]
GO
