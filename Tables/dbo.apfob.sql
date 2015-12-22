CREATE TABLE [dbo].[apfob]
(
[timestamp] [timestamp] NOT NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dlvry_code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apfob_ind_0] ON [dbo].[apfob] ([fob_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apfob] TO [public]
GO
GRANT SELECT ON  [dbo].[apfob] TO [public]
GO
GRANT INSERT ON  [dbo].[apfob] TO [public]
GO
GRANT DELETE ON  [dbo].[apfob] TO [public]
GO
GRANT UPDATE ON  [dbo].[apfob] TO [public]
GO
