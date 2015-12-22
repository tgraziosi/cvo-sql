CREATE TABLE [dbo].[rpt_glledgerdet]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [datetime] NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_balance] [float] NOT NULL,
[balance] [float] NOT NULL,
[period_end_date] [int] NOT NULL,
[period_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glledgerdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glledgerdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glledgerdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glledgerdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glledgerdet] TO [public]
GO
