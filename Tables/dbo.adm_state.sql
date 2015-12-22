CREATE TABLE [dbo].[adm_state]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [state1] ON [dbo].[adm_state] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_state] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_state] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_state] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_state] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_state] TO [public]
GO
