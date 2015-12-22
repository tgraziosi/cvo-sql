CREATE TABLE [dbo].[ep_temp_glref_acct_type]
(
[seq_id] [int] NOT NULL IDENTITY(1, 1),
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_flag] [int] NULL,
[reference_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[ep_temp_glref_acct_type] TO [public]
GO
GRANT INSERT ON  [dbo].[ep_temp_glref_acct_type] TO [public]
GO
GRANT DELETE ON  [dbo].[ep_temp_glref_acct_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[ep_temp_glref_acct_type] TO [public]
GO
