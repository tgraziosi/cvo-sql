CREATE TABLE [dbo].[CVO_orders_all_Hist]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[req_ship_date] [datetime] NOT NULL,
[sch_ship_date] [datetime] NULL,
[date_shipped] [datetime] NULL,
[date_entered] [datetime] NOT NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routing] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_date] [datetime] NULL,
[total_invoice] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__CVO_order__total__6DF5371B] DEFAULT ((0)),
[total_amt_order] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__CVO_order__total__6EE95B54] DEFAULT ((0)),
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_perc] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__CVO_order__tax_p__6FDD7F8D] DEFAULT ((0)),
[invoice_no] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__freig__70D1A3C6] DEFAULT ((0)),
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[discount] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__disco__71C5C7FF] DEFAULT ((0)),
[label_no] [int] NULL,
[cancel_date] [datetime] NULL,
[new] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cash_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_orders__type__72B9EC38] DEFAULT ('I'),
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_allow_pct] [decimal] (20, 8) NULL,
[route_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_no] [decimal] (20, 8) NULL,
[date_printed] [datetime] NULL,
[date_transfered] [datetime] NULL,
[cr_invoice_no] [int] NULL,
[who_picked] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[changed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[forwarder_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_comm] [decimal] (20, 8) NULL,
[freight_allow_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_dfpa] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_tax] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__total__73AE1071] DEFAULT ((0)),
[total_discount] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__total__74A234AA] DEFAULT ((0)),
[f_note] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_edi] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_batch] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[post_edi_date] [datetime] NULL,
[blanket] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gross_sales] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__gross__759658E3] DEFAULT ((0)),
[load_no] [int] NULL CONSTRAINT [DF__CVO_order__load___768A7D1C] DEFAULT ((0)),
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_factor] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__curr___777EA155] DEFAULT ((1)),
[bill_to_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oper_factor] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__oper___7872C58E] DEFAULT ((1)),
[tot_ord_tax] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__tot_o__7966E9C7] DEFAULT ((0)),
[tot_ord_disc] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__tot_o__7A5B0E00] DEFAULT ((0)),
[tot_ord_freight] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__tot_o__7B4F3239] DEFAULT ((0)),
[posting_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[orig_no] [int] NULL CONSTRAINT [DF__CVO_order__orig___7C435672] DEFAULT ((0)),
[orig_ext] [int] NULL CONSTRAINT [DF__CVO_order__orig___7D377AAB] DEFAULT ((0)),
[tot_tax_incl] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__tot_t__7E2B9EE4] DEFAULT ((0)),
[process_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__proce__7F1FC31D] DEFAULT (' '),
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__batch__0013E756] DEFAULT ('0'),
[tot_ord_incl] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_order__tot_o__01080B8F] DEFAULT ((0)),
[barcode_status] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[multiple_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__CVO_order__multi__01FC2FC8] DEFAULT ('N'),
[so_priority_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FO_order_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket_amt] [float] NULL,
[user_priority] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_date] [datetime] NULL,
[to_date] [datetime] NULL,
[consolidate_flag] [smallint] NULL,
[proc_inv_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_def_fld1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_def_fld2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_def_fld3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_def_fld4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_def_fld5] [float] NULL,
[user_def_fld6] [float] NULL,
[user_def_fld7] [float] NULL,
[user_def_fld8] [float] NULL,
[user_def_fld9] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_def_fld10] [int] NULL,
[user_def_fld11] [int] NULL,
[user_def_fld12] [int] NULL,
[eprocurement_ind] [int] NULL,
[sold_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sopick_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_picked_dt] [datetime] NULL,
[internal_so_ind] [int] NULL,
[ship_to_country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_valid_ind] [int] NULL,
[addr_valid_ind] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_orders_all_Hist_idx2_101613] ON [dbo].[CVO_orders_all_Hist] ([cust_code], [type]) INCLUDE ([status], [order_no], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_orders_all_hist_idx1_043013] ON [dbo].[CVO_orders_all_Hist] ([date_shipped]) INCLUDE ([ship_to], [ext], [invoice_date], [invoice_no], [order_no], [user_category], [type], [cust_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ordextcust] ON [dbo].[CVO_orders_all_Hist] ([order_no], [ext]) INCLUDE ([cust_code], [ship_to]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ordextinvdate] ON [dbo].[CVO_orders_all_Hist] ([order_no], [ext]) INCLUDE ([invoice_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ordextsalesperson] ON [dbo].[CVO_orders_all_Hist] ([order_no], [ext]) INCLUDE ([salesperson]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ordextpromo] ON [dbo].[CVO_orders_all_Hist] ([order_no], [ext]) INCLUDE ([user_def_fld9], [user_def_fld3]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ord1] ON [dbo].[CVO_orders_all_Hist] ([order_no], [ext], [cust_code], [ship_to], [date_shipped], [date_entered], [total_invoice], [total_amt_order], [salesperson], [type], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [History] ON [dbo].[CVO_orders_all_Hist] ([order_no], [ext], [cust_code], [ship_to], [date_shipped], [type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [for_coop] ON [dbo].[CVO_orders_all_Hist] ([order_no], [ext], [cust_code], [status], [invoice_date], [type]) INCLUDE ([tot_ord_disc], [total_amt_order]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_orders_all_hist_ind_stat_date_slp] ON [dbo].[CVO_orders_all_Hist] ([status], [date_entered], [salesperson]) INCLUDE ([ship_to], [cust_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>] ON [dbo].[CVO_orders_all_Hist] ([status], [date_shipped]) INCLUDE ([order_no], [user_def_fld4], [user_category], [type], [cust_code], [ship_to], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_orders_all_Hist_idx3_101613] ON [dbo].[CVO_orders_all_Hist] ([type], [status]) INCLUDE ([order_no], [cust_code], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_ord_hist_for_adord_vw] ON [dbo].[CVO_orders_all_Hist] ([type], [who_entered]) INCLUDE ([status], [date_entered], [ship_to], [order_no], [user_category], [cust_code], [ext], [date_shipped]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_orders_all_Hist] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_orders_all_Hist] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_orders_all_Hist] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_orders_all_Hist] TO [public]
GO
