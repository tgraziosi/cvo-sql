CREATE TABLE [dbo].[rpt_appdbmemh]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_order_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ticket_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_posted] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state_flag] [smallint] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_restock] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_misc] [float] NOT NULL,
[amt_net] [float] NOT NULL,
[user_id] [smallint] NOT NULL,
[amt_tfm] [float] NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[intercompany_flag] [smallint] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_short_name] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[flag_det] [smallint] NOT NULL,
[flag_tax] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appdbmemh] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appdbmemh] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appdbmemh] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appdbmemh] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appdbmemh] TO [public]
GO
