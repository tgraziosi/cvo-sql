CREATE TABLE [dbo].[tdc_EDI_ord_list]
(
[ASN] [int] NOT NULL,
[order_no] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ordered_qty] [decimal] (20, 8) NOT NULL,
[ordered_uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[packed_qty] [decimal] (20, 8) NOT NULL,
[packed_uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[shipped_qty] [decimal] (20, 8) NOT NULL,
[shipped_uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UPC] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[volume] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_EDI_ord_list] ADD CONSTRAINT [PK_tdc_EDI_ord_list] PRIMARY KEY NONCLUSTERED  ([ASN], [order_no], [line_no], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_EDI_ord_list] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_EDI_ord_list] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_EDI_ord_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_EDI_ord_list] TO [public]
GO
