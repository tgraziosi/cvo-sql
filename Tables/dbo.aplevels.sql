CREATE TABLE [dbo].[aplevels]
(
[timestamp] [timestamp] NOT NULL,
[manager_level] [smallint] NOT NULL,
[amt_max] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [aplevels_ind_0] ON [dbo].[aplevels] ([manager_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aplevels] TO [public]
GO
GRANT SELECT ON  [dbo].[aplevels] TO [public]
GO
GRANT INSERT ON  [dbo].[aplevels] TO [public]
GO
GRANT DELETE ON  [dbo].[aplevels] TO [public]
GO
GRANT UPDATE ON  [dbo].[aplevels] TO [public]
GO
