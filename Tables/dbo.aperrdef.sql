CREATE TABLE [dbo].[aperrdef]
(
[timestamp] [timestamp] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_code] [int] NOT NULL,
[e_level] [int] NOT NULL,
[e_active] [smallint] NOT NULL,
[e_sdesc] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aperrdef_idx_0] ON [dbo].[aperrdef] ([e_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aperrdef] TO [public]
GO
GRANT SELECT ON  [dbo].[aperrdef] TO [public]
GO
GRANT INSERT ON  [dbo].[aperrdef] TO [public]
GO
GRANT DELETE ON  [dbo].[aperrdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[aperrdef] TO [public]
GO
