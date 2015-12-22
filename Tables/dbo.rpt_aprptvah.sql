CREATE TABLE [dbo].[rpt_aprptvah]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_net] [float] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_trx_type_code_old] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_trx_type_code_new] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num_old] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num_new] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ticket_num_old] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ticket_num_new] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_order_num_old] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_order_num_new] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code_old] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code_new] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_code_old] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_code_new] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc_old] [datetime] NULL,
[date_doc_new] [datetime] NULL,
[date_required_old] [datetime] NULL,
[date_required_new] [datetime] NULL,
[date_received_old] [datetime] NULL,
[date_received_new] [datetime] NULL,
[date_due_old] [datetime] NULL,
[date_due_new] [datetime] NULL,
[date_aging_old] [datetime] NULL,
[date_aging_new] [datetime] NULL,
[date_discount_old] [datetime] NULL,
[date_discount_new] [datetime] NULL,
[date_applied] [datetime] NULL,
[user_id] [smallint] NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[amt_adjusted] [float] NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aprptvah] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aprptvah] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aprptvah] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aprptvah] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aprptvah] TO [public]
GO
