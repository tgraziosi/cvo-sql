CREATE TABLE [dbo].[rpt_arrptstm]
(
[image_id] [int] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attn_cont_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dunn_msg] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stmnt_msg] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bracket1] [float] NULL,
[bracket2] [float] NULL,
[bracket3] [float] NULL,
[bracket4] [float] NULL,
[bracket5] [float] NULL,
[bracket6] [float] NULL,
[cust_total] [float] NULL,
[na_tier_label] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[na_tier_total] [float] NULL,
[sort_by] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sort_by_doc_date] [datetime] NULL,
[sort_by_doc_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_apply_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_apply_type] [smallint] NULL,
[trx_type] [smallint] NULL,
[trx_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [float] NULL,
[rate_home] [float] NULL,
[rate_oper] [float] NULL,
[date_aging] [datetime] NULL,
[date_doc] [datetime] NULL,
[date_due] [datetime] NULL,
[date_applied] [datetime] NULL,
[date_aged_on] [datetime] NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NULL,
[curr_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bracket7] [float] NULL,
[parent_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ftp] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_paid_to_date] [float] NULL,
[p_contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_value] [float] NULL,
[orig_value] [float] NULL,
[ref_id] [int] NULL,
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_ftp] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_payment] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arrptstm] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arrptstm] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arrptstm] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arrptstm] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arrptstm] TO [public]
GO
