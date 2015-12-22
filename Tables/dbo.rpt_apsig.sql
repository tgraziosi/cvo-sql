CREATE TABLE [dbo].[rpt_apsig]
(
[image_id] [int] NOT NULL,
[image_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[image] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apsig] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apsig] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apsig] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apsig] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apsig] TO [public]
GO
