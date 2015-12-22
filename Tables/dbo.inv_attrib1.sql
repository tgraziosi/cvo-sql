CREATE TABLE [dbo].[inv_attrib1]
(
[timestamp] [timestamp] NOT NULL,
[attrib1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_attrib1] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_attrib1] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_attrib1] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_attrib1] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_attrib1] TO [public]
GO
