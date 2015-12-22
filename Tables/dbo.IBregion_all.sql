CREATE TABLE [dbo].[IBregion_all]
(
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[parent_outline_num] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[parent_region_flag] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IBregion_all_i1] ON [dbo].[IBregion_all] ([org_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IBregion_all_i2] ON [dbo].[IBregion_all] ([region_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[IBregion_all] TO [public]
GO
GRANT SELECT ON  [dbo].[IBregion_all] TO [public]
GO
GRANT INSERT ON  [dbo].[IBregion_all] TO [public]
GO
GRANT DELETE ON  [dbo].[IBregion_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[IBregion_all] TO [public]
GO
