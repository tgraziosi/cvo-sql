CREATE TABLE [dbo].[gl_glctrycvt]
(
[timestamp] [timestamp] NOT NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ctry_code_int] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_glctrycvt_0] ON [dbo].[gl_glctrycvt] ([country_code], [ctry_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_glctrycvt] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glctrycvt] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glctrycvt] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glctrycvt] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glctrycvt] TO [public]
GO
