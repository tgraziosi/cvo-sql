CREATE TABLE [dbo].[glrecdet]
(
[timestamp] [timestamp] NOT NULL,
[sequence_id] [int] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_2] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount_period_1] [float] NOT NULL,
[amount_period_2] [float] NOT NULL,
[amount_period_3] [float] NOT NULL,
[amount_period_4] [float] NOT NULL,
[amount_period_5] [float] NOT NULL,
[amount_period_6] [float] NOT NULL,
[amount_period_7] [float] NOT NULL,
[amount_period_8] [float] NOT NULL,
[amount_period_9] [float] NOT NULL,
[amount_period_10] [float] NOT NULL,
[amount_period_11] [float] NOT NULL,
[amount_period_12] [float] NOT NULL,
[amount_period_13] [float] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[date_applied] [int] NOT NULL,
[offset_flag] [smallint] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_ref_id] [int] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [glrecdet_ind_0] ON [dbo].[glrecdet] ([journal_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glrecdet] TO [public]
GO
GRANT SELECT ON  [dbo].[glrecdet] TO [public]
GO
GRANT INSERT ON  [dbo].[glrecdet] TO [public]
GO
GRANT DELETE ON  [dbo].[glrecdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[glrecdet] TO [public]
GO
