CREATE TABLE [dbo].[tdc_EDI_shipment_header]
(
[ASN] [int] NOT NULL,
[cust_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [int] NOT NULL CONSTRAINT [DF__tdc_EDI_s__statu__2779321E] DEFAULT ((-1)),
[SCAC] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[carrier_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carrier_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carrier_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_date] [datetime] NOT NULL,
[num_of_orders] [int] NOT NULL,
[num_of_cartons] [int] NOT NULL,
[total_weight] [decimal] (20, 8) NOT NULL,
[weight_uom] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[authorization_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[package_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[envelop_control_number] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_control_number] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[document_control_number] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[envelop_date_time] [datetime] NULL,
[seal_number] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pro_number] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_charge_term] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_bill_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_bill_to_adr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_bill_to_street] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_bill_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_bill_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_bill_to_zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_EDI_shipment_header] ADD CONSTRAINT [CK_tdc_EDI_shipment_header] CHECK (([status]=(33) OR [status]=(3) OR [status]=(2) OR [status]=(1) OR [status]=(0) OR [status]=((-1))))
GO
ALTER TABLE [dbo].[tdc_EDI_shipment_header] ADD CONSTRAINT [PK_tdc_EDI_shipment_header] PRIMARY KEY NONCLUSTERED  ([ASN], [cust_code], [ship_to_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_EDI_shipment_header] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_EDI_shipment_header] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_EDI_shipment_header] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_EDI_shipment_header] TO [public]
GO
