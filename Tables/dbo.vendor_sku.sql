CREATE TABLE [dbo].[vendor_sku]
(
[timestamp] [timestamp] NOT NULL,
[sku_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_recv_date] [datetime] NOT NULL,
[vendor_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_sku] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_price] [decimal] (20, 8) NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [vendor_sku_ind_sku_date_fend_qty_curr] ON [dbo].[vendor_sku] ([sku_no], [last_recv_date], [vendor_no], [qty], [curr_key]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[vendor_sku] TO [public]
GO
GRANT SELECT ON  [dbo].[vendor_sku] TO [public]
GO
GRANT INSERT ON  [dbo].[vendor_sku] TO [public]
GO
GRANT DELETE ON  [dbo].[vendor_sku] TO [public]
GO
GRANT UPDATE ON  [dbo].[vendor_sku] TO [public]
GO
