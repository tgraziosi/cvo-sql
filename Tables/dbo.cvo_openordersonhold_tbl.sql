CREATE TABLE [dbo].[cvo_openordersonhold_tbl]
(
[order_no] [int] NULL,
[ext] [int] NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routing] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Territory] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_amt_order] [decimal] (20, 8) NULL,
[total_discount] [decimal] (20, 8) NULL,
[Net_Sale_Amount] [decimal] (21, 8) NULL,
[total_tax] [decimal] (20, 8) NULL,
[freight] [decimal] (20, 8) NULL,
[qty_ordered] [decimal] (38, 8) NULL,
[qty_shipped] [decimal] (38, 8) NULL,
[total_invoice] [decimal] (23, 8) NULL,
[invoice_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_invoice] [datetime] NULL,
[date_entered] [datetime] NULL,
[date_sch_ship] [datetime] NULL,
[date_shipped] [datetime] NULL,
[status] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_desc] [varchar] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipped_flag] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[orig_no] [int] NULL,
[orig_ext] [int] NULL,
[promo_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FramesOrdered] [decimal] (38, 8) NULL,
[FramesShipped] [decimal] (38, 8) NULL,
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Cust_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HS_order_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[allocation_date] [datetime] NULL,
[x_date_invoice] [int] NULL,
[x_date_entered] [int] NULL,
[x_date_sch_ship] [int] NULL,
[x_date_shipped] [int] NULL,
[source] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Region] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_descr] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adm_hold_reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_dept] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerType] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OpenAR] [real] NULL,
[DaysToShip] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[net_sales] [real] NULL,
[salesperson_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_address] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[slp_phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fill_pct] [decimal] (8, 2) NULL,
[action_rep] [tinyint] NULL,
[action_cus] [tinyint] NULL,
[note] [varchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [idx_pr] ON [dbo].[cvo_openordersonhold_tbl] ([order_no], [ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_openordersonhold_tbl] TO [public]
GO
