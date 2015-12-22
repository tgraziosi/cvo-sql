CREATE TABLE [dbo].[cvo_rx_consolidate_ref_log]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[soft_alloc_no] [int] NULL,
[handshake_no] [int] NULL,
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sch_ship_date] [datetime] NULL,
[delivery_date] [datetime] NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carrier] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[caller] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_rx_consolidate_ref_log] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_rx_consolidate_ref_log] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_rx_consolidate_ref_log] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_rx_consolidate_ref_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_rx_consolidate_ref_log] TO [public]
GO
