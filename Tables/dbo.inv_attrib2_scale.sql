CREATE TABLE [dbo].[inv_attrib2_scale]
(
[timestamp] [timestamp] NOT NULL,
[attrib2_scale_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attrib2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ndx1_inv_attrib2_scale] ON [dbo].[inv_attrib2_scale] ([attrib2_scale_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_attrib2_scale] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_attrib2_scale] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_attrib2_scale] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_attrib2_scale] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_attrib2_scale] TO [public]
GO
