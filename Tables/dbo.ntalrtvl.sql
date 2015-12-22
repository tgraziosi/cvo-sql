CREATE TABLE [dbo].[ntalrtvl]
(
[alert_id] [int] NOT NULL,
[de1] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[de2] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ntalrtvl] TO [public]
GO
GRANT SELECT ON  [dbo].[ntalrtvl] TO [public]
GO
GRANT INSERT ON  [dbo].[ntalrtvl] TO [public]
GO
GRANT DELETE ON  [dbo].[ntalrtvl] TO [public]
GO
GRANT UPDATE ON  [dbo].[ntalrtvl] TO [public]
GO
