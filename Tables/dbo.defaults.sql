CREATE TABLE [dbo].[defaults]
(
[timestamp] [timestamp] NOT NULL,
[dw_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[col_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_val] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [deflt1] ON [dbo].[defaults] ([dw_name], [col_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[defaults] TO [public]
GO
GRANT SELECT ON  [dbo].[defaults] TO [public]
GO
GRANT INSERT ON  [dbo].[defaults] TO [public]
GO
GRANT DELETE ON  [dbo].[defaults] TO [public]
GO
GRANT UPDATE ON  [dbo].[defaults] TO [public]
GO
