CREATE TABLE [dbo].[rpt_crdrtn]
(
[customer_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[line_no] [int] NULL,
[part_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ord_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_ordered] [float] NULL,
[qty_shipped] [float] NULL,
[price] [float] NULL,
[price_type] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[date_shipped] [datetime] NULL,
[ord_location] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cr_ordered] [float] NULL,
[cr_shipped] [float] NULL,
[cr_reason_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_crdrtn] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_crdrtn] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_crdrtn] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_crdrtn] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_crdrtn] TO [public]
GO
