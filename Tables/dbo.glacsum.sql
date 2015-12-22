CREATE TABLE [dbo].[glacsum]
(
[timestamp] [timestamp] NOT NULL,
[account_code] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[app_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glacsum_ind_0] ON [dbo].[glacsum] ([account_code], [app_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glacsum] TO [public]
GO
GRANT SELECT ON  [dbo].[glacsum] TO [public]
GO
GRANT INSERT ON  [dbo].[glacsum] TO [public]
GO
GRANT DELETE ON  [dbo].[glacsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[glacsum] TO [public]
GO
