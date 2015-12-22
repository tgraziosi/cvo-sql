CREATE TABLE [dbo].[rpt_amassetclass]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[classification_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[classification_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[classification_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amassetclass] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amassetclass] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amassetclass] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amassetclass] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amassetclass] TO [public]
GO
