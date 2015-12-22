CREATE TABLE [dbo].[arstat]
(
[timestamp] [timestamp] NOT NULL,
[status_type] [smallint] NOT NULL,
[status_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arstat_ind_1] ON [dbo].[arstat] ([status_code]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arstat_ind_0] ON [dbo].[arstat] ([status_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arstat] TO [public]
GO
GRANT SELECT ON  [dbo].[arstat] TO [public]
GO
GRANT INSERT ON  [dbo].[arstat] TO [public]
GO
GRANT DELETE ON  [dbo].[arstat] TO [public]
GO
GRANT UPDATE ON  [dbo].[arstat] TO [public]
GO
