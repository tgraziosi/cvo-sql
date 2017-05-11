CREATE TABLE [dbo].[cvo_promo_override_audit]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[override_date] [datetime] NULL CONSTRAINT [DF__cvo_promo__overr__28E4EB72] DEFAULT (getdate()),
[override_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[failure_reason] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_promo_ovr_ord_ext] ON [dbo].[cvo_promo_override_audit] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_promo_override_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_promo_override_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_promo_override_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_promo_override_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_promo_override_audit] TO [public]
GO
