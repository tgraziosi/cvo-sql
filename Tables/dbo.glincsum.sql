CREATE TABLE [dbo].[glincsum]
(
[timestamp] [timestamp] NOT NULL,
[sequence_id] [int] NOT NULL,
[account_pattern] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[re_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glincsum_ind_0] ON [dbo].[glincsum] ([account_pattern]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glincsum] TO [public]
GO
GRANT SELECT ON  [dbo].[glincsum] TO [public]
GO
GRANT INSERT ON  [dbo].[glincsum] TO [public]
GO
GRANT DELETE ON  [dbo].[glincsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[glincsum] TO [public]
GO
