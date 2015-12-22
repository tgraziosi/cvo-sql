CREATE TABLE [dbo].[rpt_ordent]
(
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[line_no] [int] NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ordered] [decimal] (20, 8) NULL,
[shipped] [decimal] (20, 8) NULL,
[curr_price] [decimal] (20, 8) NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[date_shipped] [datetime] NULL,
[sch_ship_date] [datetime] NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NULL,
[invoice_no] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ordent] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ordent] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ordent] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ordent] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ordent] TO [public]
GO
