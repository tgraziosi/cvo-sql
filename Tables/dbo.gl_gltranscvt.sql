CREATE TABLE [dbo].[gl_gltranscvt]
(
[timestamp] [timestamp] NOT NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_code_int] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_gltranscvt_0] ON [dbo].[gl_gltranscvt] ([country_code], [trans_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_gltranscvt] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_gltranscvt] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_gltranscvt] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_gltranscvt] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_gltranscvt] TO [public]
GO
