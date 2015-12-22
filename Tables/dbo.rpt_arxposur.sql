CREATE TABLE [dbo].[rpt_arxposur]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[date_due] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[amount] [float] NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_end_date] [int] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_rate_home] [float] NOT NULL,
[apply_rate_oper] [float] NOT NULL,
[asof_rate_home] [float] NOT NULL,
[asof_rate_oper] [float] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arxposur] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arxposur] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arxposur] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arxposur] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arxposur] TO [public]
GO
