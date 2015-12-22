CREATE TABLE [dbo].[rpt_appyregh]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc2] [datetime] NULL,
[date_applied] [datetime] NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payee_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_net] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[print_batch_num] [int] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[no_details] [smallint] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[group_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_by2] [datetime] NULL,
[home_oper_rate] [float] NOT NULL,
[cash_acct_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[out_of_sequence] [smallint] NOT NULL,
[void_flag] [smallint] NOT NULL,
[link] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[local_flag] [smallint] NOT NULL,
[amt_on_acct] [float] NULL,
[local_date_applied] [int] NULL,
[local_adj_date_applied] [int] NULL,
[date_doc] [int] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appyregh] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appyregh] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appyregh] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appyregh] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appyregh] TO [public]
GO
