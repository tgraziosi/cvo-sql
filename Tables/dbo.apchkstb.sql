CREATE TABLE [dbo].[apchkstb]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[check_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[print_batch_num] [int] NOT NULL,
[payment_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[print_acct_num] [smallint] NOT NULL,
[payment_memo] [smallint] NOT NULL,
[voucher_classification] [smallint] NOT NULL,
[voucher_comment] [smallint] NOT NULL,
[voucher_memo] [smallint] NOT NULL,
[voucher_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_paid] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[amt_net] [float] NOT NULL,
[invoice_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_date] [int] NOT NULL,
[voucher_date_due] [int] NOT NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[voucher_classify] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[voucher_internal_memo] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [smallint] NOT NULL,
[printed_flag] [smallint] NOT NULL,
[overflow_flag] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[history_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apchkstb_ind_5] ON [dbo].[apchkstb] ([cash_acct_code], [check_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apchkstb_ind_4] ON [dbo].[apchkstb] ([invoice_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apchkstb_ind_2] ON [dbo].[apchkstb] ([payment_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apchkstb_ind_3] ON [dbo].[apchkstb] ([payment_num], [overflow_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apchkstb_ind_1] ON [dbo].[apchkstb] ([vendor_code], [check_num], [cash_acct_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apchkstb_ind_0] ON [dbo].[apchkstb] ([vendor_code], [payment_num], [voucher_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apchkstb] TO [public]
GO
GRANT SELECT ON  [dbo].[apchkstb] TO [public]
GO
GRANT INSERT ON  [dbo].[apchkstb] TO [public]
GO
GRANT DELETE ON  [dbo].[apchkstb] TO [public]
GO
GRANT UPDATE ON  [dbo].[apchkstb] TO [public]
GO
