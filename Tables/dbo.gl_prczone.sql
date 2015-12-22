CREATE TABLE [dbo].[gl_prczone]
(
[timestamp] [timestamp] NOT NULL,
[zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cv_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prc_border] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_prczone_0] ON [dbo].[gl_prczone] ([zone_code], [cv_zone_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_prczone] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_prczone] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_prczone] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_prczone] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_prczone] TO [public]
GO
