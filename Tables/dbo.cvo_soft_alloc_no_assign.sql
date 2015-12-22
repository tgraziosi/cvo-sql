CREATE TABLE [dbo].[cvo_soft_alloc_no_assign]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[soft_alloc_no] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_no_assign_ind0] ON [dbo].[cvo_soft_alloc_no_assign] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_no_assign_ind1] ON [dbo].[cvo_soft_alloc_no_assign] ([soft_alloc_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_soft_alloc_no_assign] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_soft_alloc_no_assign] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_soft_alloc_no_assign] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_soft_alloc_no_assign] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_soft_alloc_no_assign] TO [public]
GO
