CREATE TABLE [dbo].[ksync]
(
[section] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[keyname] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[keyvalue] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IDXksync] ON [dbo].[ksync] ([section], [keyname]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[ksync] TO [public]
GO
GRANT INSERT ON  [dbo].[ksync] TO [public]
GO
GRANT DELETE ON  [dbo].[ksync] TO [public]
GO
GRANT UPDATE ON  [dbo].[ksync] TO [public]
GO
