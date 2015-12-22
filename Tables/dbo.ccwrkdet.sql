CREATE TABLE [dbo].[ccwrkdet]
(
[workload_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[workload_clause] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [tinyint] NULL,
[type] [tinyint] NULL,
[datatype] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ccwrkdet_idx] ON [dbo].[ccwrkdet] ([workload_code], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ccwrkdet] TO [public]
GO
GRANT SELECT ON  [dbo].[ccwrkdet] TO [public]
GO
GRANT INSERT ON  [dbo].[ccwrkdet] TO [public]
GO
GRANT DELETE ON  [dbo].[ccwrkdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccwrkdet] TO [public]
GO
