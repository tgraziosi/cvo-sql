CREATE TABLE [dbo].[calc_stats]
(
[workload_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[period_number] [smallint] NULL,
[EndDate] [datetime] NULL,
[end_date] [int] NULL,
[period_sales] [float] NULL,
[total_home] [float] NULL,
[amt_age_bracket1] [float] NULL,
[amt_age_bracket2] [float] NULL,
[amt_age_bracket3] [float] NULL,
[amt_age_bracket4] [float] NULL,
[amt_age_bracket5] [float] NULL,
[amt_age_bracket6] [float] NULL,
[ab1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ab2] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ab3] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ab4] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ab5] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ab6] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fromcust] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thrucust] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CompanyName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AllCust] [smallint] NULL,
[AllWorkload] [smallint] NULL,
[CurSymbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FromWkld] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ThruWkld] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[workload_desc] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_ar_bal] [float] NULL,
[avg_days_pay] [int] NULL,
[min_cust_date] [int] NULL,
[min_co_date] [int] NULL,
[total_cust_sales] [float] NULL,
[total_co_sales] [float] NULL,
[total_cust_days] [int] NULL,
[total_co_days] [int] NULL,
[total_cust_ar] [float] NULL,
[total_co_ar] [float] NULL,
[cust_dso] [int] NULL,
[co_dso] [int] NULL,
[PeriodType] [smallint] NULL,
[start_date_str] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_date_str] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[my_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[all_org_flag] [smallint] NULL,
[from_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[thru_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_age_bracket0] [float] NULL,
[ab0] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[calc_stats] TO [public]
GO
GRANT SELECT ON  [dbo].[calc_stats] TO [public]
GO
GRANT INSERT ON  [dbo].[calc_stats] TO [public]
GO
GRANT DELETE ON  [dbo].[calc_stats] TO [public]
GO
GRANT UPDATE ON  [dbo].[calc_stats] TO [public]
GO
