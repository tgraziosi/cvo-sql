CREATE TABLE [dbo].[arzone]
(
[timestamp] [timestamp] NOT NULL,
[zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[zone_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arzone_ind_0] ON [dbo].[arzone] ([zone_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arzone] TO [public]
GO
GRANT SELECT ON  [dbo].[arzone] TO [public]
GO
GRANT INSERT ON  [dbo].[arzone] TO [public]
GO
GRANT DELETE ON  [dbo].[arzone] TO [public]
GO
GRANT UPDATE ON  [dbo].[arzone] TO [public]
GO
