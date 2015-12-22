CREATE TABLE [dbo].[cvo_stage]
(
[stage_no] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cvo_stage_ind0] ON [dbo].[cvo_stage] ([stage_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_stage] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_stage] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_stage] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_stage] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_stage] TO [public]
GO
