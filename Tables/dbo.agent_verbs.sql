CREATE TABLE [dbo].[agent_verbs]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [averbs1] ON [dbo].[agent_verbs] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[agent_verbs] TO [public]
GO
GRANT SELECT ON  [dbo].[agent_verbs] TO [public]
GO
GRANT INSERT ON  [dbo].[agent_verbs] TO [public]
GO
GRANT DELETE ON  [dbo].[agent_verbs] TO [public]
GO
GRANT UPDATE ON  [dbo].[agent_verbs] TO [public]
GO
