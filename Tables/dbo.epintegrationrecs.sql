CREATE TABLE [dbo].[epintegrationrecs]
(
[id_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [smallint] NOT NULL,
[action] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[proc_flag] [tinyint] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[epintegrationrecs] TO [public]
GO
GRANT INSERT ON  [dbo].[epintegrationrecs] TO [public]
GO
GRANT DELETE ON  [dbo].[epintegrationrecs] TO [public]
GO
GRANT UPDATE ON  [dbo].[epintegrationrecs] TO [public]
GO
