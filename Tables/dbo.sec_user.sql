CREATE TABLE [dbo].[sec_user]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[password] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[language] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__sec_user__langua__120088F9] DEFAULT ('E')
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sec_usr] ON [dbo].[sec_user] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sec_user] TO [public]
GO
GRANT SELECT ON  [dbo].[sec_user] TO [public]
GO
GRANT INSERT ON  [dbo].[sec_user] TO [public]
GO
GRANT DELETE ON  [dbo].[sec_user] TO [public]
GO
GRANT UPDATE ON  [dbo].[sec_user] TO [public]
GO
