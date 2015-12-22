CREATE TABLE [dbo].[gl_gltrans]
(
[timestamp] [timestamp] NOT NULL,
[trans_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_gltrans_0] ON [dbo].[gl_gltrans] ([trans_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_gltrans] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_gltrans] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_gltrans] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_gltrans] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_gltrans] TO [public]
GO
