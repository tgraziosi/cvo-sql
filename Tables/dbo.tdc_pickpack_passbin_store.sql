CREATE TABLE [dbo].[tdc_pickpack_passbin_store]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[line_no] [int] NULL,
[alloc_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[passbin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pickpack_passbin_store_idx1] ON [dbo].[tdc_pickpack_passbin_store] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pickpack_passbin_store] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pickpack_passbin_store] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pickpack_passbin_store] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pickpack_passbin_store] TO [public]
GO
