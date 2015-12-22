CREATE TABLE [dbo].[inv_attrib_style_master]
(
[timestamp] [timestamp] NOT NULL,
[base_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attrib1_scale_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attrib2_scale_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entered_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entered_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_attrib_style_master] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_attrib_style_master] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_attrib_style_master] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_attrib_style_master] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_attrib_style_master] TO [public]
GO
