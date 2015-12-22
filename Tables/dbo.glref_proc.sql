CREATE TABLE [dbo].[glref_proc]
(
[timestamp] [timestamp] NOT NULL,
[ref_code_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glref_proc] TO [public]
GO
GRANT SELECT ON  [dbo].[glref_proc] TO [public]
GO
GRANT INSERT ON  [dbo].[glref_proc] TO [public]
GO
GRANT DELETE ON  [dbo].[glref_proc] TO [public]
GO
GRANT UPDATE ON  [dbo].[glref_proc] TO [public]
GO
