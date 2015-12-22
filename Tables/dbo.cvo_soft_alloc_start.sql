CREATE TABLE [dbo].[cvo_soft_alloc_start]
(
[order_no] [int] NULL,
[order_ext] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_soft_alloc_start_ind0] ON [dbo].[cvo_soft_alloc_start] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_soft_alloc_start] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_soft_alloc_start] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_soft_alloc_start] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_soft_alloc_start] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_soft_alloc_start] TO [public]
GO
