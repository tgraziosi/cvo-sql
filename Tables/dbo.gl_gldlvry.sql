CREATE TABLE [dbo].[gl_gldlvry]
(
[timestamp] [timestamp] NOT NULL,
[dlvry_code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dlvry_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_gldlvry_0] ON [dbo].[gl_gldlvry] ([dlvry_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_gldlvry] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_gldlvry] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_gldlvry] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_gldlvry] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_gldlvry] TO [public]
GO
