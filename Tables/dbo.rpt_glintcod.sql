CREATE TABLE [dbo].[rpt_glintcod]
(
[org_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_mode] [smallint] NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_comp_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_comp_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_comp_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_comp_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_ic_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_ic_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_over_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glintcod] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glintcod] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glintcod] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glintcod] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glintcod] TO [public]
GO
