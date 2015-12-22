CREATE TABLE [dbo].[apzone]
(
[timestamp] [timestamp] NOT NULL,
[zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[zone_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apzone_ind_0] ON [dbo].[apzone] ([zone_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apzone] TO [public]
GO
GRANT SELECT ON  [dbo].[apzone] TO [public]
GO
GRANT INSERT ON  [dbo].[apzone] TO [public]
GO
GRANT DELETE ON  [dbo].[apzone] TO [public]
GO
GRANT UPDATE ON  [dbo].[apzone] TO [public]
GO
