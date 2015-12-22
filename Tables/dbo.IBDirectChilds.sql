CREATE TABLE [dbo].[IBDirectChilds]
(
[parent_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[parent_outline_num] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_outline_num] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_region_flag] [int] NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[region_outline_num] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[IBDirectChilds] TO [public]
GO
GRANT SELECT ON  [dbo].[IBDirectChilds] TO [public]
GO
GRANT INSERT ON  [dbo].[IBDirectChilds] TO [public]
GO
GRANT DELETE ON  [dbo].[IBDirectChilds] TO [public]
GO
GRANT UPDATE ON  [dbo].[IBDirectChilds] TO [public]
GO
