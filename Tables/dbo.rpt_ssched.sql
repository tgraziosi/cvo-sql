CREATE TABLE [dbo].[rpt_ssched]
(
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[line_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ordered] [decimal] (20, 8) NULL,
[shipped] [decimal] (20, 8) NULL,
[price] [decimal] (20, 8) NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[date_shipped] [datetime] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sch_ship_date] [datetime] NULL,
[ship_to_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ssched] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ssched] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ssched] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ssched] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ssched] TO [public]
GO
