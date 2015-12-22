CREATE TABLE [dbo].[arcommnt]
(
[timestamp] [timestamp] NOT NULL,
[comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arcommnt_ind_0] ON [dbo].[arcommnt] ([comment_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcommnt] TO [public]
GO
GRANT SELECT ON  [dbo].[arcommnt] TO [public]
GO
GRANT INSERT ON  [dbo].[arcommnt] TO [public]
GO
GRANT DELETE ON  [dbo].[arcommnt] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcommnt] TO [public]
GO
