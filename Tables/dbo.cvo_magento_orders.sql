CREATE TABLE [dbo].[cvo_magento_orders]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[mg_order_id] [bigint] NULL,
[order_date] [datetime] NULL,
[update_date] [datetime] NULL,
[grand_total] [float] NULL,
[customer_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_magento_orders] ADD CONSTRAINT [PK__cvo_magento_orde__61A8CB16] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
