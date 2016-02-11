CREATE TABLE [dbo].[gltrxdet]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_id] [smallint] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_2] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[nat_balance] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate] [float] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[date_posted] [int] NOT NULL,
[trx_type] [smallint] NOT NULL,
[offset_flag] [smallint] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_ref_id] [int] NOT NULL,
[balance_oper] [float] NULL,
[rate_oper] [float] NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [frx_tran] ON [dbo].[gltrxdet] ([account_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [gltrxdet_ind_1] ON [dbo].[gltrxdet] ([journal_ctrl_num], [account_code]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [gltrxdet_ind_0] ON [dbo].[gltrxdet] ([journal_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [gltrxdet_ind_2] ON [dbo].[gltrxdet] ([rec_company_code], [journal_ctrl_num], [org_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltrxdet] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrxdet] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrxdet] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrxdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrxdet] TO [public]
GO
