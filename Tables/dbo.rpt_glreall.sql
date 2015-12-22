CREATE TABLE [dbo].[rpt_glreall]
(
[sequence_id] [int] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_posted] [int] NOT NULL,
[date_last_applied] [int] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hold_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[based_type] [smallint] NOT NULL,
[budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nonfin_budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[intercompany_flag] [smallint] NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[offset_flag] [smallint] NOT NULL,
[to_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glreall] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glreall] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glreall] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glreall] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glreall] TO [public]
GO
