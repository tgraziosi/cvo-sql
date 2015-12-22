CREATE TABLE [dbo].[apnumber]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[next_voucher_num] [int] NOT NULL,
[voucher_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vo_start_col] [smallint] NOT NULL,
[vo_length] [smallint] NOT NULL,
[next_vendor_num] [int] NOT NULL,
[vendor_num_mask] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_adj_trx] [int] NOT NULL,
[adj_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_cash_disb_num] [int] NOT NULL,
[cash_disb_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_disb_start_col] [smallint] NOT NULL,
[cash_disb_length] [smallint] NOT NULL,
[next_dm_num] [int] NOT NULL,
[dm_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dm_start_col] [smallint] NOT NULL,
[dm_length] [smallint] NOT NULL,
[next_batch_ctrl_num] [int] NOT NULL,
[batch_ctrl_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_pay_to_num] [int] NOT NULL,
[pay_to_num_mask] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_gen_id] [int] NOT NULL,
[next_print_batch_num] [int] NOT NULL,
[next_settlement_num] [int] NOT NULL,
[settlement_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[settlement_start_col] [smallint] NOT NULL,
[settlement_length] [smallint] NOT NULL,
[next_accrual_num] [int] NOT NULL,
[accrual_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acc_start_col] [smallint] NOT NULL,
[acc_length] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apnumber_ind_0] ON [dbo].[apnumber] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apnumber] TO [public]
GO
GRANT SELECT ON  [dbo].[apnumber] TO [public]
GO
GRANT INSERT ON  [dbo].[apnumber] TO [public]
GO
GRANT DELETE ON  [dbo].[apnumber] TO [public]
GO
GRANT UPDATE ON  [dbo].[apnumber] TO [public]
GO
