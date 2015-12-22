CREATE TABLE [dbo].[glreadet]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [smallint] NOT NULL,
[date_posted] [int] NOT NULL,
[balance] [float] NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[offset_flag] [smallint] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_ref_id] [int] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [glreadet_ind_0] ON [dbo].[glreadet] ([journal_ctrl_num], [account_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glreadet] TO [public]
GO
GRANT SELECT ON  [dbo].[glreadet] TO [public]
GO
GRANT INSERT ON  [dbo].[glreadet] TO [public]
GO
GRANT DELETE ON  [dbo].[glreadet] TO [public]
GO
GRANT UPDATE ON  [dbo].[glreadet] TO [public]
GO
