CREATE TABLE [dbo].[sec_constraints]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[table_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[constrain_by] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [seccons1] ON [dbo].[sec_constraints] ([kys], [table_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sec_constraints] TO [public]
GO
GRANT SELECT ON  [dbo].[sec_constraints] TO [public]
GO
GRANT INSERT ON  [dbo].[sec_constraints] TO [public]
GO
GRANT DELETE ON  [dbo].[sec_constraints] TO [public]
GO
GRANT UPDATE ON  [dbo].[sec_constraints] TO [public]
GO
