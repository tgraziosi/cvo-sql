CREATE TABLE [dbo].[ibedterr]
(
[timestamp] [timestamp] NOT NULL,
[code] [int] NOT NULL,
[level] [int] NOT NULL,
[active] [int] NOT NULL,
[etext] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_level] [int] NOT NULL,
[default_active] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ibedterr_i1] ON [dbo].[ibedterr] ([code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ibedterr] TO [public]
GO
GRANT SELECT ON  [dbo].[ibedterr] TO [public]
GO
GRANT INSERT ON  [dbo].[ibedterr] TO [public]
GO
GRANT DELETE ON  [dbo].[ibedterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibedterr] TO [public]
GO
