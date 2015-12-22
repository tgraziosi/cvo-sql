CREATE TABLE [dbo].[ccwrkusr]
(
[workload_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ccwrkusr_idx] ON [dbo].[ccwrkusr] ([workload_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ccwrkusr] TO [public]
GO
GRANT SELECT ON  [dbo].[ccwrkusr] TO [public]
GO
GRANT INSERT ON  [dbo].[ccwrkusr] TO [public]
GO
GRANT DELETE ON  [dbo].[ccwrkusr] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccwrkusr] TO [public]
GO
