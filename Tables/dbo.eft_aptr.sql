CREATE TABLE [dbo].[eft_aptr]
(
[timestamp] [timestamp] NOT NULL,
[payment_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[voucher_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_paid] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[amt_net] [float] NOT NULL,
[invoice_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_date] [int] NOT NULL,
[voucher_date_due] [int] NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[voucher_classify] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[voucher_internal_memo] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dest_account_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dest_account_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dest_aba_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dest_account_type] [smallint] NOT NULL,
[print_batch_num] [int] NOT NULL,
[eft_batch_num] [int] NOT NULL,
[process_flag] [smallint] NOT NULL,
[process_date] [int] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bank_account_encrypted] [varbinary] (max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [eft_aptr_ind_1] ON [dbo].[eft_aptr] ([cash_acct_code], [vendor_code], [pay_to_code], [payment_num]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [eft_aptr_ind_0] ON [dbo].[eft_aptr] ([cash_acct_code], [vendor_code], [payment_num], [voucher_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [eft_aptr_ind_2] ON [dbo].[eft_aptr] ([payment_code], [cash_acct_code], [nat_cur_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eft_aptr] TO [public]
GO
GRANT SELECT ON  [dbo].[eft_aptr] TO [public]
GO
GRANT INSERT ON  [dbo].[eft_aptr] TO [public]
GO
GRANT DELETE ON  [dbo].[eft_aptr] TO [public]
GO
GRANT UPDATE ON  [dbo].[eft_aptr] TO [public]
GO
