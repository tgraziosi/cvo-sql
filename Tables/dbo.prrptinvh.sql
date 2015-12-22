CREATE TABLE [dbo].[prrptinvh]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [smallint] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[not_prev_printed] [smallint] NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_doc] [datetime] NULL,
[date_due] [datetime] NULL,
[amt_net] [float] NULL,
[amt_discount] [float] NULL,
[amt_freight] [float] NULL,
[amt_tax] [float] NULL,
[amt_gross] [float] NULL,
[amt_paid] [float] NULL,
[amt_due] [float] NULL,
[customer_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_po_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
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
[copies] [smallint] NULL,
[rel_cust] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NULL,
[image_id] [int] NULL,
[groupby] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prt_address] [smallint] NULL,
[prt_copy] [smallint] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prrptinvh] TO [public]
GO
GRANT SELECT ON  [dbo].[prrptinvh] TO [public]
GO
GRANT INSERT ON  [dbo].[prrptinvh] TO [public]
GO
GRANT DELETE ON  [dbo].[prrptinvh] TO [public]
GO
GRANT UPDATE ON  [dbo].[prrptinvh] TO [public]
GO
