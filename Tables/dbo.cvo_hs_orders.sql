CREATE TABLE [dbo].[cvo_hs_orders]
(
[hs_order_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_hs_orders] ADD CONSTRAINT [PK__cvo_hs_orders__456D4A72] PRIMARY KEY CLUSTERED  ([hs_order_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_hs_orders] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_hs_orders] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_hs_orders] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_hs_orders] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_hs_orders] TO [public]
GO
