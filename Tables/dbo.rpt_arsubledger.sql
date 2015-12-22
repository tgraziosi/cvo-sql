CREATE TABLE [dbo].[rpt_arsubledger]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[beginning_bal] [float] NOT NULL,
[debit] [float] NOT NULL,
[credit] [float] NOT NULL,
[ending_bal] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arsubledger] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arsubledger] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arsubledger] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arsubledger] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arsubledger] TO [public]
GO
