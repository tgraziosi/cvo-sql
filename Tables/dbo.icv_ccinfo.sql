CREATE TABLE [dbo].[icv_ccinfo]
(
[timestamp] [timestamp] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address_type] [smallint] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NULL,
[prompt1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prompt2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prompt3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prompt4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [smallint] NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[preload] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_address_type_3890DFC2] ON [dbo].[icv_ccinfo] ([address_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_customer_code_3890DFC2] ON [dbo].[icv_ccinfo] ([customer_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_payment_code_3890DFC2] ON [dbo].[icv_ccinfo] ([payment_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_ship_to_code_3890DFC2] ON [dbo].[icv_ccinfo] ([ship_to_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_ccinfo] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_ccinfo] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_ccinfo] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_ccinfo] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_ccinfo] TO [public]
GO
