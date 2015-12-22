CREATE TABLE [dbo].[rpt_soinvsumm]
(
[order_no] [int] NOT NULL,
[date_entered] [datetime] NOT NULL,
[date_shipped] [datetime] NULL,
[invoice_no] [int] NULL,
[invoice_date] [datetime] NULL,
[total_invoice] [decimal] (20, 8) NOT NULL,
[total_amt_order] [decimal] (20, 8) NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[discount] [decimal] (20, 8) NULL,
[changed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight] [decimal] (20, 8) NULL,
[freight_allow_pct] [decimal] (20, 8) NULL,
[freight_allow_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ext] [int] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_factor] [decimal] (20, 8) NULL,
[num_precision] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_soinvsumm] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_soinvsumm] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_soinvsumm] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_soinvsumm] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_soinvsumm] TO [public]
GO
