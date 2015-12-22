CREATE TABLE [dbo].[aprptvoh]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_order_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ticket_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NULL,
[date_posted] [datetime] NULL,
[date_applied] [datetime] NULL,
[date_aging] [datetime] NULL,
[date_due] [datetime] NULL,
[date_doc] [datetime] NULL,
[date_received] [datetime] NULL,
[date_required] [datetime] NULL,
[date_paid] [datetime] NULL,
[date_discount] [datetime] NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recurring_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_misc] [float] NOT NULL,
[amt_net] [float] NOT NULL,
[amt_paid_to_date] [float] NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[symbol] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[groupby] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[voucher_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[one_per_check] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aprptvoh] TO [public]
GO
GRANT SELECT ON  [dbo].[aprptvoh] TO [public]
GO
GRANT INSERT ON  [dbo].[aprptvoh] TO [public]
GO
GRANT DELETE ON  [dbo].[aprptvoh] TO [public]
GO
GRANT UPDATE ON  [dbo].[aprptvoh] TO [public]
GO
