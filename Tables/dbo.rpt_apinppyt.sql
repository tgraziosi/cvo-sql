CREATE TABLE [dbo].[rpt_apinppyt]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[amt_payment] [float] NOT NULL,
[amt_pyt] [float] NOT NULL,
[amt_on_acct] [float] NOT NULL,
[user_id] [smallint] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[print_batch_num] [int] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[printed_flag] [smallint] NOT NULL,
[gen_id] [int] NOT NULL,
[approval_flag] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_oper] [float] NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_format_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payee_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_precision] [smallint] NOT NULL,
[home_amt_payment] [float] NOT NULL,
[home_amt_pyt] [float] NOT NULL,
[home_amt_on_acct] [float] NOT NULL,
[home_amt_disc_taken] [float] NOT NULL,
[oper_amt_payment] [float] NOT NULL,
[oper_amt_pyt] [float] NOT NULL,
[oper_amt_on_acct] [float] NOT NULL,
[oper_amt_disc_taken] [float] NOT NULL,
[details_count] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [rpt_apinppyt_idx_0] ON [dbo].[rpt_apinppyt] ([trx_ctrl_num], [trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apinppyt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apinppyt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apinppyt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apinppyt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apinppyt] TO [public]
GO
