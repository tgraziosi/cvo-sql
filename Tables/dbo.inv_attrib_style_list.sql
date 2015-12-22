CREATE TABLE [dbo].[inv_attrib_style_list]
(
[timestamp] [timestamp] NOT NULL,
[base_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attrib1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attrib2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ndx_inv_attrib_style_list1] ON [dbo].[inv_attrib_style_list] ([base_part_no], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_attrib_style_list] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_attrib_style_list] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_attrib_style_list] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_attrib_style_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_attrib_style_list] TO [public]
GO
