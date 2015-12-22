CREATE TABLE [dbo].[arterr]
(
[timestamp] [timestamp] NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [EAI_Integration] ON [dbo].[arterr] ([ddid]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arterr_ind_0] ON [dbo].[arterr] ([territory_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arterr] TO [public]
GO
GRANT SELECT ON  [dbo].[arterr] TO [public]
GO
GRANT INSERT ON  [dbo].[arterr] TO [public]
GO
GRANT DELETE ON  [dbo].[arterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[arterr] TO [public]
GO
