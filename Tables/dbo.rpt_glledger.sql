CREATE TABLE [dbo].[rpt_glledger]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_type] [smallint] NOT NULL,
[beginning_bal] [float] NOT NULL,
[ending_bal] [float] NOT NULL,
[debit] [float] NOT NULL,
[credit] [float] NOT NULL,
[group_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_by_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glledger] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glledger] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glledger] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glledger] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glledger] TO [public]
GO
