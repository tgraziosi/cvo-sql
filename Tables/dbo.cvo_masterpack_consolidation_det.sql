CREATE TABLE [dbo].[cvo_masterpack_consolidation_det]
(
[consolidation_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_masterpack_consolidation_det_inx01] ON [dbo].[cvo_masterpack_consolidation_det] ([consolidation_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_masterpack_consolidation_det_inx02] ON [dbo].[cvo_masterpack_consolidation_det] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_masterpack_consolidation_det_pk] ON [dbo].[cvo_masterpack_consolidation_det] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_masterpack_consolidation_det] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_masterpack_consolidation_det] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_masterpack_consolidation_det] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_masterpack_consolidation_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_masterpack_consolidation_det] TO [public]
GO
