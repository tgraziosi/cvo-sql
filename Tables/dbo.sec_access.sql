CREATE TABLE [dbo].[sec_access]
(
[timestamp] [timestamp] NOT NULL,
[user_key] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[access] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [key_sec_access] ON [dbo].[sec_access] ([user_key], [module_key]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sec_access] TO [public]
GO
GRANT SELECT ON  [dbo].[sec_access] TO [public]
GO
GRANT INSERT ON  [dbo].[sec_access] TO [public]
GO
GRANT DELETE ON  [dbo].[sec_access] TO [public]
GO
GRANT UPDATE ON  [dbo].[sec_access] TO [public]
GO
