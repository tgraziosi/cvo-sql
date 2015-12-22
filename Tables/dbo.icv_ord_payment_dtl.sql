CREATE TABLE [dbo].[icv_ord_payment_dtl]
(
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[sequence] [int] NOT NULL,
[auth_sequence] [int] NOT NULL,
[response_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rej_reason] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[approval_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avs_result] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[proc_date] [datetime] NULL,
[ord_amt] [decimal] (20, 8) NULL,
[trans_type] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_ext_3C6170A6] ON [dbo].[icv_ord_payment_dtl] ([ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_order_no_3C6170A6] ON [dbo].[icv_ord_payment_dtl] ([order_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_ord_payment_dtl] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_ord_payment_dtl] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_ord_payment_dtl] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_ord_payment_dtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_ord_payment_dtl] TO [public]
GO
