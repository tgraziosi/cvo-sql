CREATE TABLE [dbo].[glchart_proc]
(
[timestamp] [timestamp] NOT NULL,
[account_code_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glchart_proc] TO [public]
GO
GRANT SELECT ON  [dbo].[glchart_proc] TO [public]
GO
GRANT INSERT ON  [dbo].[glchart_proc] TO [public]
GO
GRANT DELETE ON  [dbo].[glchart_proc] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchart_proc] TO [public]
GO
