CREATE TABLE [dbo].[rpt_gltrxdet]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_id] [smallint] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_2] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[balance_oper] [float] NOT NULL,
[nat_balance] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[date_posted] [int] NOT NULL,
[trx_type] [smallint] NOT NULL,
[offset_flag] [smallint] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[db_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_format_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_gltrxdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_gltrxdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_gltrxdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_gltrxdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_gltrxdet] TO [public]
GO
