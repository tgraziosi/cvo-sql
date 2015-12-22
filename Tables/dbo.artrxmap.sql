CREATE TABLE [dbo].[artrxmap]
(
[artrx_type] [smallint] NOT NULL,
[age_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxmap_ind_1] ON [dbo].[artrxmap] ([age_type], [artrx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxmap_ind_0] ON [dbo].[artrxmap] ([artrx_type], [age_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artrxmap] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxmap] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxmap] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxmap] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxmap] TO [public]
GO
