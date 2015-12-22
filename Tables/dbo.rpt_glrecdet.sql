CREATE TABLE [dbo].[rpt_glrecdet]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_2] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[period] [int] NOT NULL,
[period_start_date] [int] NOT NULL,
[period_end_date] [int] NOT NULL,
[period_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NOT NULL,
[account_format_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[db_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glrecdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glrecdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glrecdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glrecdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glrecdet] TO [public]
GO
