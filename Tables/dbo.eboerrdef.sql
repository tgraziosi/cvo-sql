CREATE TABLE [dbo].[eboerrdef]
(
[timestamp] [timestamp] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[e_code] [int] NULL,
[e_level] [int] NULL,
[e_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[e_active] [smallint] NULL,
[e_sdesc] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eboerrdef_idx_0] ON [dbo].[eboerrdef] ([e_code], [e_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [eboerrdef_idx_1] ON [dbo].[eboerrdef] ([e_sdesc]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [eboerrdef_idx_2] ON [dbo].[eboerrdef] ([e_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [eboerrdef_idx_3] ON [dbo].[eboerrdef] ([e_type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[eboerrdef] TO [public]
GO
GRANT INSERT ON  [dbo].[eboerrdef] TO [public]
GO
GRANT DELETE ON  [dbo].[eboerrdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[eboerrdef] TO [public]
GO
