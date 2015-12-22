CREATE TABLE [dbo].[aredterr]
(
[timestamp] [timestamp] NOT NULL,
[client_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_code] [int] NOT NULL,
[e_level] [int] NOT NULL,
[e_active] [int] NOT NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_level_default] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aredterr_ind_0] ON [dbo].[aredterr] ([e_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aredterr] TO [public]
GO
GRANT SELECT ON  [dbo].[aredterr] TO [public]
GO
GRANT INSERT ON  [dbo].[aredterr] TO [public]
GO
GRANT DELETE ON  [dbo].[aredterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[aredterr] TO [public]
GO
