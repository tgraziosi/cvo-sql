CREATE TABLE [dbo].[ccorgcfg]
(
[all_org_flag] [smallint] NOT NULL,
[from_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ccorgcfg] TO [public]
GO
GRANT SELECT ON  [dbo].[ccorgcfg] TO [public]
GO
GRANT INSERT ON  [dbo].[ccorgcfg] TO [public]
GO
GRANT DELETE ON  [dbo].[ccorgcfg] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccorgcfg] TO [public]
GO
