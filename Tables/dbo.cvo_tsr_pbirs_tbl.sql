CREATE TABLE [dbo].[cvo_tsr_pbirs_tbl]
(
[region] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Sales_type] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[month] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_month] [int] NULL,
[ty_monthsales] [real] NULL,
[ly_monthsales] [real] NULL,
[ly_month_tot_sales] [real] NULL,
[ly_monthsales_ytd] [real] NULL,
[asofdate] [datetime] NULL,
[id] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_tsr_date] ON [dbo].[cvo_tsr_pbirs_tbl] ([asofdate] DESC) ON [PRIMARY]
GO
