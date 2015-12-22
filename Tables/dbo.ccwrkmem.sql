CREATE TABLE [dbo].[ccwrkmem]
(
[workload_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ccwrkmem_idx] ON [dbo].[ccwrkmem] ([workload_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ccwrkmem] TO [public]
GO
GRANT SELECT ON  [dbo].[ccwrkmem] TO [public]
GO
GRANT INSERT ON  [dbo].[ccwrkmem] TO [public]
GO
GRANT DELETE ON  [dbo].[ccwrkmem] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccwrkmem] TO [public]
GO
