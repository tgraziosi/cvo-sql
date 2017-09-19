CREATE TABLE [dbo].[cvo_promo_order_category]
(
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [int] NULL,
[category] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_promo_order_category_ind0] ON [dbo].[cvo_promo_order_category] ([promo_id], [promo_level], [line_no]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_promo_order_category] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_promo_order_category] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_promo_order_category] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_promo_order_category] TO [public]
GO
