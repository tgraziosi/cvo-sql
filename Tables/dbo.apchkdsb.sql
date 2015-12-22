CREATE TABLE [dbo].[apchkdsb]
(
[check_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[onacct_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[check_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apchkdsb_ind_0] ON [dbo].[apchkdsb] ([check_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apchkdsb] TO [public]
GO
GRANT SELECT ON  [dbo].[apchkdsb] TO [public]
GO
GRANT INSERT ON  [dbo].[apchkdsb] TO [public]
GO
GRANT DELETE ON  [dbo].[apchkdsb] TO [public]
GO
GRANT UPDATE ON  [dbo].[apchkdsb] TO [public]
GO
