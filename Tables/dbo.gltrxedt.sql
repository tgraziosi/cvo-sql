CREATE TABLE [dbo].[gltrxedt]
(
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
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [float] NOT NULL,
[nat_balance] [float] NOT NULL,
[trx_type] [smallint] NOT NULL,
[offset_flag] [smallint] NOT NULL,
[seq_ref_id] [int] NOT NULL,
[temp_flag] [smallint] NOT NULL,
[spid] [smallint] NOT NULL,
[oper_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[balance_oper] [float] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [gltrxedt_ind_1] ON [dbo].[gltrxedt] ([spid], [journal_ctrl_num], [sequence_id], [temp_flag]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [gltrxedt_ind_0] ON [dbo].[gltrxedt] ([spid], [rec_company_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltrxedt] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrxedt] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrxedt] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrxedt] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrxedt] TO [public]
GO
