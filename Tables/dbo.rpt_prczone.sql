CREATE TABLE [dbo].[rpt_prczone]
(
[zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[zone_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cv_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cv_zone_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prc_border] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_prczone] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_prczone] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_prczone] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_prczone] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_prczone] TO [public]
GO
