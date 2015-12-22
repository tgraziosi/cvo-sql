CREATE TABLE [dbo].[glappid]
(
[timestamp] [timestamp] NOT NULL,
[app_id] [int] NOT NULL,
[app_name] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glappid_ind_0] ON [dbo].[glappid] ([app_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glappid] TO [public]
GO
GRANT SELECT ON  [dbo].[glappid] TO [public]
GO
GRANT INSERT ON  [dbo].[glappid] TO [public]
GO
GRANT DELETE ON  [dbo].[glappid] TO [public]
GO
GRANT UPDATE ON  [dbo].[glappid] TO [public]
GO
