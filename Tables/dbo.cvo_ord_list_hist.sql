CREATE TABLE [dbo].[cvo_ord_list_hist]
(
[timestamp] [timestamp] NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[line_no] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_entered] [datetime] NULL,
[ordered] [decimal] (20, 8) NULL,
[shipped] [decimal] (20, 8) NULL,
[price] [float] NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [decimal] (20, 8) NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_comm] [decimal] (20, 8) NULL,
[temp_price] [decimal] (20, 8) NULL,
[temp_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cr_ordered] [decimal] (20, 8) NULL,
[cr_shipped] [decimal] (20, 8) NULL,
[discount] [decimal] (20, 8) NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_ord_li__void__6B0D1221] DEFAULT ('N'),
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[std_cost] [decimal] (20, 8) NULL,
[cubic_feet] [decimal] (20, 8) NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_ord_l__lb_tr__6C01365A] DEFAULT ('N'),
[labor] [decimal] (20, 8) NULL,
[direct_dolrs] [decimal] (20, 8) NULL,
[ovhd_dolrs] [decimal] (20, 8) NULL,
[util_dolrs] [decimal] (20, 8) NULL,
[taxable] [int] NULL,
[weight_ea] [decimal] (20, 8) NULL,
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_ord_l__qc_fl__6CF55A93] DEFAULT ('N'),
[reason_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[qc_no] [int] NULL CONSTRAINT [DF__cvo_ord_l__qc_no__6DE97ECC] DEFAULT ((0)),
[rejected] [decimal] (20, 8) NULL CONSTRAINT [DF__cvo_ord_l__rejec__6EDDA305] DEFAULT ((0)),
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_ord_l__part___6FD1C73E] DEFAULT ('P'),
[orig_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_tax] [decimal] (20, 8) NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_price] [decimal] (20, 8) NULL,
[oper_price] [decimal] (20, 8) NULL,
[display_line] [int] NULL,
[std_direct_dolrs] [decimal] (20, 8) NULL,
[std_ovhd_dolrs] [decimal] (20, 8) NULL,
[std_util_dolrs] [decimal] (20, 8) NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contract] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[agreement_id] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[service_agreement_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_available_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_po_flag] [smallint] NULL,
[load_group_no] [int] NULL,
[return_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_count] [int] NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[picked_dt] [datetime] NULL,
[who_picked_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed_dt] [datetime] NULL,
[who_unpicked_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unpicked_dt] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_ord_list_hist_inx01] ON [dbo].[cvo_ord_list_hist] ([order_no], [order_ext]) INCLUDE ([reason_code], [price], [shipped], [ordered], [part_no], [cr_ordered], [cr_shipped], [return_code], [discount]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_ord_list_hist_inx02] ON [dbo].[cvo_ord_list_hist] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_ord_list_hist_inx03] ON [dbo].[cvo_ord_list_hist] ([order_no], [order_ext], [location], [part_no], [shipped]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [CVO_ord_list_hist_inx04] ON [dbo].[cvo_ord_list_hist] ([order_no], [order_ext], [part_no], [shipped], [time_entered]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_ord_list_hist] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ord_list_hist] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ord_list_hist] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ord_list_hist] TO [public]
GO
