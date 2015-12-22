CREATE TABLE [dbo].[tdc_inbound_ASN_serial_err]
(
[ASN] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SSCC] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GTIN] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPC_TAG] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carton_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serial_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NOT NULL,
[err_msg] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_serial_err_indx1] ON [dbo].[tdc_inbound_ASN_serial_err] ([ASN], [SSCC], [carton_no], [po_no], [part_no], [lot_ser], [serial_no], [GTIN], [EPC_TAG]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_inbound_ASN_serial_err] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_inbound_ASN_serial_err] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_inbound_ASN_serial_err] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_inbound_ASN_serial_err] TO [public]
GO
