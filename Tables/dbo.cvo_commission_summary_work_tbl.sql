CREATE TABLE [dbo].[cvo_commission_summary_work_tbl]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[salesperson] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hiredate] [smalldatetime] NULL,
[amount] [numeric] (12, 2) NULL,
[comm_amt] [numeric] (12, 2) NULL,
[draw_amount] [numeric] (12, 2) NULL,
[commission] [numeric] (8, 2) NULL,
[incentivePC] [tinyint] NULL,
[incentive] [numeric] (18, 2) NULL,
[other_additions] [numeric] (18, 2) NULL,
[reduction] [numeric] (18, 2) NULL,
[addition_rsn] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reduction_rsn] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rep_type] [tinyint] NULL,
[status_type] [tinyint] NULL,
[territory] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_earnings] [numeric] (12, 2) NULL,
[total_draw] [numeric] (12, 2) NULL,
[prior_month_bal] [numeric] (12, 2) NULL,
[net_pay] [numeric] (12, 2) NULL,
[report_month] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_detail] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_sum] [numeric] (12, 2) NULL,
[draw_weeks] [int] NULL,
[region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [pk_commis_summary_tbl] ON [dbo].[cvo_commission_summary_work_tbl] ([salesperson], [territory], [report_month]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_commission_summary_work_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_commission_summary_work_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_commission_summary_work_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_commission_summary_work_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_commission_summary_work_tbl] TO [public]
GO
