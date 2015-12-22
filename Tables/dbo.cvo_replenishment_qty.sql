CREATE TABLE [dbo].[cvo_replenishment_qty]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cvo_replenishment_qty_pk] ON [dbo].[cvo_replenishment_qty] ([location], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_replenishment_qty] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_replenishment_qty] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_replenishment_qty] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_replenishment_qty] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_replenishment_qty] TO [public]
GO
