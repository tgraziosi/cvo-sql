CREATE TABLE [dbo].[arinthdr]
(
[link] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [smallint] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_trx_type] [smallint] NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_applied] [int] NULL,
[date_doc] [int] NULL,
[date_aging] [int] NULL,
[date_due] [int] NULL,
[date_shipped] [int] NULL,
[date_required] [int] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fin_chg_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[recurring_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_po_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_flag] [smallint] NULL,
[hold_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_type] [smallint] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_home] [float] NULL,
[rate_oper] [float] NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed_flag] [smallint] NULL,
[amt_freight] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[arinthdr] ADD CONSTRAINT [PK__arinthdr__42F40205] PRIMARY KEY CLUSTERED  ([link]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arinthdr] TO [public]
GO
GRANT SELECT ON  [dbo].[arinthdr] TO [public]
GO
GRANT INSERT ON  [dbo].[arinthdr] TO [public]
GO
GRANT DELETE ON  [dbo].[arinthdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinthdr] TO [public]
GO
