CREATE TABLE [dbo].[rpt_cmrechst]
(
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_reconciled] [int] NOT NULL,
[amount_reconciled] [float] NOT NULL,
[currency_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_precision] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmrechst] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmrechst] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmrechst] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmrechst] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmrechst] TO [public]
GO
