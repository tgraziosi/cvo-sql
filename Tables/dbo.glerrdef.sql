CREATE TABLE [dbo].[glerrdef]
(
[timestamp] [timestamp] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_code] [int] NOT NULL,
[e_level] [int] NOT NULL,
[e_active] [smallint] NOT NULL,
[e_sdesc] [char] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glerrdef_ind_0] ON [dbo].[glerrdef] ([e_code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [glerrdef_ind_1] ON [dbo].[glerrdef] ([e_sdesc]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glerrdef] TO [public]
GO
GRANT SELECT ON  [dbo].[glerrdef] TO [public]
GO
GRANT INSERT ON  [dbo].[glerrdef] TO [public]
GO
GRANT DELETE ON  [dbo].[glerrdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[glerrdef] TO [public]
GO
