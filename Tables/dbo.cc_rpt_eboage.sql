CREATE TABLE [dbo].[cc_rpt_eboage]
(
[trx_type] [smallint] NULL,
[ref_id] [smallint] NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_po_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_trx_type] [smallint] NULL,
[sub_apply_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_apply_type] [smallint] NULL,
[date_doc] [datetime] NULL,
[date_due] [datetime] NULL,
[date_aging] [datetime] NULL,
[date_applied] [datetime] NULL,
[amount] [float] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_home] [float] NULL,
[rate_oper] [float] NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_3] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_4] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_5] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_6] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_7] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_8] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child_9] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[groupby0] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[groupby1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[groupby2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[groupby3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bracket] [smallint] NULL,
[days_aged] [int] NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_type] [smallint] NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NULL,
[num_currencies] [smallint] NULL,
[date_entered] [int] NULL,
[my_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_rpt_eboage] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_rpt_eboage] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_rpt_eboage] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_rpt_eboage] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_rpt_eboage] TO [public]
GO
