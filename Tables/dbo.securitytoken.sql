CREATE TABLE [dbo].[securitytoken]
(
[timestamp] [timestamp] NOT NULL,
[security_token] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[create_date] [datetime] NOT NULL,
[create_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[securitytoken] TO [public]
GO
GRANT SELECT ON  [dbo].[securitytoken] TO [public]
GO
GRANT INSERT ON  [dbo].[securitytoken] TO [public]
GO
GRANT DELETE ON  [dbo].[securitytoken] TO [public]
GO
GRANT UPDATE ON  [dbo].[securitytoken] TO [public]
GO
