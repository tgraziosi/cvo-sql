CREATE TABLE [dbo].[cmerrdef]
(
[timestamp] [timestamp] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_code] [int] NOT NULL,
[e_level] [int] NOT NULL,
[e_active] [smallint] NOT NULL,
[e_sdesc] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmerrdef_ind_0] ON [dbo].[cmerrdef] ([client_id], [e_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cmerrdef_ind_2] ON [dbo].[cmerrdef] ([e_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cmerrdef_ind_1] ON [dbo].[cmerrdef] ([e_sdesc]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmerrdef] TO [public]
GO
GRANT SELECT ON  [dbo].[cmerrdef] TO [public]
GO
GRANT INSERT ON  [dbo].[cmerrdef] TO [public]
GO
GRANT DELETE ON  [dbo].[cmerrdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmerrdef] TO [public]
GO
