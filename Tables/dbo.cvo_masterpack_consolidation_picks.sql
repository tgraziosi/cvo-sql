CREATE TABLE [dbo].[cvo_masterpack_consolidation_picks]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[consolidation_no] [int] NOT NULL,
[parent_tran_id] [int] NOT NULL,
[child_tran_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_masterpack_consolidation_picks_inx01] ON [dbo].[cvo_masterpack_consolidation_picks] ([consolidation_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_masterpack_consolidation_picks_inx02] ON [dbo].[cvo_masterpack_consolidation_picks] ([parent_tran_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_masterpack_consolidation_picks_pk] ON [dbo].[cvo_masterpack_consolidation_picks] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_masterpack_consolidation_picks] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_masterpack_consolidation_picks] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_masterpack_consolidation_picks] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_masterpack_consolidation_picks] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_masterpack_consolidation_picks] TO [public]
GO
