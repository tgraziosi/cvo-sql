CREATE TABLE [dbo].[tdc_inbound_ASN_serial_history]
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
[direction] [int] NOT NULL CONSTRAINT [DF__tdc_inbou__direc__4F872378] DEFAULT ((1)),
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NOT NULL,
[err_msg] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[receipt_no] [int] NULL,
[tran_date] [datetime] NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_inbound_ASN_serial_history] ADD CONSTRAINT [CK_ASN_serial_trans] CHECK (([trans]='DELETED' OR [trans]='REJECTED' OR [trans]='ALTRCV' OR [trans]='RCVRFID' OR [trans]='RCVASNMAN' OR [trans]='RCVASNCART' OR [trans]='RCVASNSSCC' OR [trans]='RCVASN'))
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_serial_history_indx1] ON [dbo].[tdc_inbound_ASN_serial_history] ([ASN], [SSCC], [carton_no], [po_no], [part_no], [lot_ser], [serial_no], [GTIN], [EPC_TAG]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_inbound_ASN_serial_history_indx2] ON [dbo].[tdc_inbound_ASN_serial_history] ([receipt_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_inbound_ASN_serial_history] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_inbound_ASN_serial_history] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_inbound_ASN_serial_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_inbound_ASN_serial_history] TO [public]
GO
