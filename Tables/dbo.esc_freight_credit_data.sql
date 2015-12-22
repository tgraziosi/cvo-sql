CREATE TABLE [dbo].[esc_freight_credit_data]
(
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_amt] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx0] ON [dbo].[esc_freight_credit_data] ([cust_code], [doc_ctrl_num]) ON [PRIMARY]
GO
