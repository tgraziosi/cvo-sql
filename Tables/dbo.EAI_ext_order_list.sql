CREATE TABLE [dbo].[EAI_ext_order_list]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[weight_ea] [decimal] (20, 8) NULL,
[cubic_feet] [decimal] (20, 8) NOT NULL,
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_price] [decimal] (20, 8) NOT NULL,
[discount] [decimal] (20, 8) NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[taxable] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price] [decimal] (20, 8) NOT NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_entered] [datetime] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ordersalestotal] [decimal] (20, 8) NOT NULL,
[orderdiscounttotal] [decimal] (20, 8) NOT NULL,
[ordertaxtotal] [decimal] (20, 8) NOT NULL,
[orderfreighttotal] [decimal] (20, 8) NOT NULL,
[total_tax] [decimal] (20, 8) NOT NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_ext_order_list] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_ext_order_list] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_ext_order_list] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_ext_order_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_ext_order_list] TO [public]
GO
