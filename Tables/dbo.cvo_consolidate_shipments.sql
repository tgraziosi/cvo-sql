CREATE TABLE [dbo].[cvo_consolidate_shipments]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_consolidate_shipments_ind0] ON [dbo].[cvo_consolidate_shipments] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_consolidate_shipments] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_consolidate_shipments] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_consolidate_shipments] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_consolidate_shipments] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_consolidate_shipments] TO [public]
GO
