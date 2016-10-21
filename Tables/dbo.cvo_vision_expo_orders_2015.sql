CREATE TABLE [dbo].[cvo_vision_expo_orders_2015]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[attendee_id] [int] NULL,
[hs_order_no] [int] NULL,
[cust_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_cust_id] [int] NULL,
[order_date] [datetime] NULL,
[pcs] [int] NULL,
[order_value] [float] NULL,
[added_date] [datetime] NULL,
[expo_terr] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_category] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_orders_2015] ADD CONSTRAINT [PK__cvo_vision_expo___09A70B6E] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_orders_2015] WITH NOCHECK ADD CONSTRAINT [FK__cvo_visio__expo___0A9B2FA7] FOREIGN KEY ([expo_id]) REFERENCES [dbo].[cvo_vision_expo_config] ([id])
GO
ALTER TABLE [dbo].[cvo_vision_expo_orders_2015] NOCHECK CONSTRAINT [FK__cvo_visio__expo___0A9B2FA7]
GO
