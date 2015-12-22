CREATE TABLE [dbo].[cmrechst]
(
[timestamp] [timestamp] NOT NULL,
[rec_id] [int] NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[statement_date] [int] NOT NULL,
[beginning_bal] [float] NOT NULL,
[ending_bal] [float] NOT NULL,
[closed_flag] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmrechst] TO [public]
GO
GRANT SELECT ON  [dbo].[cmrechst] TO [public]
GO
GRANT INSERT ON  [dbo].[cmrechst] TO [public]
GO
GRANT DELETE ON  [dbo].[cmrechst] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmrechst] TO [public]
GO
