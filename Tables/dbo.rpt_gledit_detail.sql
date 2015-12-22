CREATE TABLE [dbo].[rpt_gledit_detail]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[journal_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hold_flag] [smallint] NOT NULL,
[home_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[intercompany_flag] [smallint] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_flag] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[source_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_format_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[nat_balance] [float] NOT NULL,
[trx_type] [smallint] NOT NULL,
[offset_flag] [smallint] NOT NULL,
[seq_ref_id] [int] NOT NULL,
[e_code] [int] NOT NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_level] [int] NOT NULL,
[info1] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[controlling_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[detail_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[interbranch_flag] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_gledit_detail] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_gledit_detail] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_gledit_detail] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_gledit_detail] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_gledit_detail] TO [public]
GO
