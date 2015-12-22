CREATE TABLE [dbo].[cvo_st_consolidate_release]
(
[consolidation_no] [int] NULL,
[released] [int] NULL,
[release_date] [datetime] NULL,
[release_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_st_consolidate_release_ind0] ON [dbo].[cvo_st_consolidate_release] ([consolidation_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_st_consolidate_release] TO [public]
GO
