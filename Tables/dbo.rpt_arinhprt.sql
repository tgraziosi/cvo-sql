CREATE TABLE [dbo].[rpt_arinhprt]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[not_prev_printed] [smallint] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [datetime] NOT NULL,
[date_due] [datetime] NOT NULL,
[amt_net] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_paid] [float] NOT NULL,
[amt_due] [float] NOT NULL,
[customer_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_po_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NOT NULL,
[fob_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comment_line] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[copies] [smallint] NOT NULL,
[rel_cust] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NULL,
[image_id] [int] NULL,
[groupby] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tot_chg] [float] NOT NULL,
[remit_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_to_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_to_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_to_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_to_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_to_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_to_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_to_fax] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_status_desc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_store_num] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_category] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arinhprt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arinhprt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arinhprt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arinhprt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arinhprt] TO [public]
GO
