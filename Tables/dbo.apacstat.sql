CREATE TABLE [dbo].[apacstat]
(
[timestamp] [timestamp] NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unique_id] [int] NOT NULL,
[account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [int] NOT NULL,
[apply_date] [int] NOT NULL,
[process_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apacstat_ind_0] ON [dbo].[apacstat] ([account], [apply_date], [unique_id], [process_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apacstat] TO [public]
GO
GRANT SELECT ON  [dbo].[apacstat] TO [public]
GO
GRANT INSERT ON  [dbo].[apacstat] TO [public]
GO
GRANT DELETE ON  [dbo].[apacstat] TO [public]
GO
GRANT UPDATE ON  [dbo].[apacstat] TO [public]
GO
