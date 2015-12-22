CREATE TABLE [dbo].[apcommnt]
(
[timestamp] [timestamp] NOT NULL,
[comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apcommnt_ind_0] ON [dbo].[apcommnt] ([comment_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apcommnt] TO [public]
GO
GRANT SELECT ON  [dbo].[apcommnt] TO [public]
GO
GRANT INSERT ON  [dbo].[apcommnt] TO [public]
GO
GRANT DELETE ON  [dbo].[apcommnt] TO [public]
GO
GRANT UPDATE ON  [dbo].[apcommnt] TO [public]
GO
