CREATE TABLE [dbo].[cvo_psbm]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pom_date] [datetime] NULL,
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
CREATE NONCLUSTERED INDEX [idx_cvo_psbm] ON [dbo].[cvo_psbm] ([part_no], [Brand], [Model], [month], [year], [yyyymmdd]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_psbm] TO [public]
GO
