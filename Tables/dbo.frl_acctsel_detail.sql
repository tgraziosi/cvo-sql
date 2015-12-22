CREATE TABLE [dbo].[frl_acctsel_detail]
(
[acctsel_id] [numeric] (12, 0) NOT NULL,
[row_num] [smallint] NOT NULL,
[neg_sign] [smallint] NOT NULL,
[ledger_set] [smallint] NOT NULL,
[rollup_code] [smallint] NOT NULL,
[acct_type] [smallint] NOT NULL,
[acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE1frl_acctsel_detail] ON [dbo].[frl_acctsel_detail] ([acctsel_id], [acct_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[frl_acctsel_detail] TO [public]
GO
GRANT SELECT ON  [dbo].[frl_acctsel_detail] TO [public]
GO
GRANT INSERT ON  [dbo].[frl_acctsel_detail] TO [public]
GO
GRANT DELETE ON  [dbo].[frl_acctsel_detail] TO [public]
GO
GRANT UPDATE ON  [dbo].[frl_acctsel_detail] TO [public]
GO
