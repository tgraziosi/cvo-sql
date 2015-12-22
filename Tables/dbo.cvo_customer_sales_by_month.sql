CREATE TABLE [dbo].[cvo_customer_sales_by_month]
(
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[X_MONTH] [int] NULL,
[month] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[year] [int] NULL,
[asales] [float] NULL,
[areturns] [float] NULL,
[anet] [float] NULL,
[qsales] [float] NULL,
[qreturns] [float] NULL,
[qnet] [float] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_customer_sales_by_month] ON [dbo].[cvo_customer_sales_by_month] ([customer], [month], [year]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_customer_sales_by_month] TO [public]
GO
