CREATE TABLE [dbo].[gl_gldlvrycvt]
(
[timestamp] [timestamp] NOT NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dlvry_code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dlvry_code_int] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_gldlvrycvt_0] ON [dbo].[gl_gldlvrycvt] ([country_code], [dlvry_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_gldlvrycvt] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_gldlvrycvt] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_gldlvrycvt] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_gldlvrycvt] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_gldlvrycvt] TO [public]
GO
