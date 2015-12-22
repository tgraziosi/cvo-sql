CREATE TABLE [dbo].[tdc_EDI_shipment_detail]
(
[ASN] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_EDI_s__order__249CC573] DEFAULT ('SO'),
[total_amt] [decimal] (20, 8) NULL,
[amt_uom] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date_created] [datetime] NOT NULL,
[ship_to_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[num_of_items] [int] NOT NULL,
[cust_po_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_po_date] [datetime] NOT NULL,
[order_weight] [decimal] (20, 8) NULL,
[weight_uom] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[department_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_order_no] [int] NULL,
[purchaser_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_EDI_shipment_detail] ADD CONSTRAINT [PK_tdc_EDI_shipment_detail] PRIMARY KEY NONCLUSTERED  ([ASN], [order_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_EDI_shipment_detail] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_EDI_shipment_detail] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_EDI_shipment_detail] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_EDI_shipment_detail] TO [public]
GO
