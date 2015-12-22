CREATE TABLE [dbo].[inv_attrib1_scale_mstr]
(
[timestamp] [timestamp] NOT NULL,
[attrib1_scale_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ndx1_inv_attrib1_scale_mstr] ON [dbo].[inv_attrib1_scale_mstr] ([attrib1_scale_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_attrib1_scale_mstr] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_attrib1_scale_mstr] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_attrib1_scale_mstr] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_attrib1_scale_mstr] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_attrib1_scale_mstr] TO [public]
GO
