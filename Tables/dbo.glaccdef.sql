CREATE TABLE [dbo].[glaccdef]
(
[timestamp] [timestamp] NOT NULL,
[acct_format] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_col] [smallint] NOT NULL,
[length] [smallint] NOT NULL,
[acct_level] [smallint] NOT NULL,
[natural_acct_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glaccdef_ind_0] ON [dbo].[glaccdef] ([acct_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glaccdef] TO [public]
GO
GRANT SELECT ON  [dbo].[glaccdef] TO [public]
GO
GRANT INSERT ON  [dbo].[glaccdef] TO [public]
GO
GRANT DELETE ON  [dbo].[glaccdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[glaccdef] TO [public]
GO
