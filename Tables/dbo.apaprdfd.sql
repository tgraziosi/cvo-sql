CREATE TABLE [dbo].[apaprdfd]
(
[timestamp] [timestamp] NOT NULL,
[exp_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_min] [float] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [apaprdfd_ind_0] ON [dbo].[apaprdfd] ([exp_acct_code], [amt_min], [approval_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apaprdfd] TO [public]
GO
GRANT SELECT ON  [dbo].[apaprdfd] TO [public]
GO
GRANT INSERT ON  [dbo].[apaprdfd] TO [public]
GO
GRANT DELETE ON  [dbo].[apaprdfd] TO [public]
GO
GRANT UPDATE ON  [dbo].[apaprdfd] TO [public]
GO
