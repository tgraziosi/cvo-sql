CREATE TABLE [dbo].[rpt_amfacacct]
(
[fac_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fac_mask_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amfacacct] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amfacacct] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amfacacct] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amfacacct] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amfacacct] TO [public]
GO
