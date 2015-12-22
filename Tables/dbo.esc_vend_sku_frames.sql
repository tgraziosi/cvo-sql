CREATE TABLE [dbo].[esc_vend_sku_frames]
(
[sku_no] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_recv_date] [datetime] NULL,
[vendor_sku] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_Price] [float] NULL,
[Note] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Qty] [float] NULL,
[curr_key] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[esc_vend_sku_frames] TO [public]
GO
GRANT INSERT ON  [dbo].[esc_vend_sku_frames] TO [public]
GO
GRANT DELETE ON  [dbo].[esc_vend_sku_frames] TO [public]
GO
GRANT UPDATE ON  [dbo].[esc_vend_sku_frames] TO [public]
GO
