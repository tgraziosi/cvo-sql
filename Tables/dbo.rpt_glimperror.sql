CREATE TABLE [dbo].[rpt_glimperror]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_id] [smallint] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_2] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[nat_balance] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate] [float] NULL,
[posted_flag] [smallint] NULL,
[date_posted] [int] NULL,
[trx_type] [smallint] NULL,
[offset_flag] [smallint] NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_ref_id] [int] NULL,
[balance_oper] [float] NULL,
[rate_oper] [float] NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_code1] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[row_id] [int] NOT NULL,
[debit] [float] NULL,
[credit] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glimperror] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glimperror] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glimperror] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glimperror] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glimperror] TO [public]
GO
