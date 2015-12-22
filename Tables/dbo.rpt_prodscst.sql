CREATE TABLE [dbo].[rpt_prodscst]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plan_qty] [float] NULL,
[used_qty] [float] NULL,
[conv_factor] [float] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[std_cost] [float] NULL,
[prod_no] [int] NULL,
[prod_date] [datetime] NULL,
[produce_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [float] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[produce_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[produce_conv_factor] [float] NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_ext] [int] NULL,
[inventory_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[produce_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_std_cost] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_prodscst] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_prodscst] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_prodscst] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_prodscst] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_prodscst] TO [public]
GO
