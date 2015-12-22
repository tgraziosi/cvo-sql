CREATE TABLE [dbo].[rpt_prodcost]
(
[prod_no] [int] NULL,
[prod_date] [datetime] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_qty] [float] NULL,
[project_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tot_avg_cost] [float] NULL,
[direct_dolrs] [float] NULL,
[ovhd_dolrs] [float] NULL,
[util_dolrs] [float] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avg_cost] [float] NULL,
[avg_direct_dolrs] [float] NULL,
[avg_ovhd_dolrs] [float] NULL,
[avg_util_dolrs] [float] NULL,
[std_cost] [float] NULL,
[std_direct_dolrs] [float] NULL,
[std_ovhd_dolrs] [float] NULL,
[std_util_dolrs] [float] NULL,
[prod_ext] [int] NULL,
[pcl_qty] [float] NULL,
[cost] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_prodcost] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_prodcost] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_prodcost] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_prodcost] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_prodcost] TO [public]
GO
