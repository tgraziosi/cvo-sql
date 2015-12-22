CREATE TABLE [dbo].[pr_strings]
(
[id] [int] NOT NULL,
[text_value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pr_level] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [pr_strings_ix1] ON [dbo].[pr_strings] ([id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_strings] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_strings] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_strings] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_strings] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_strings] TO [public]
GO
