CREATE TABLE [dbo].[rpt_prodvar]
(
[list_part_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[list_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[list_plan_qty] [float] NULL,
[list_used_qty] [float] NULL,
[list_conv_factor] [float] NULL,
[list_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[std_cost] [float] NULL,
[prod_no] [int] NULL,
[prod_date] [datetime] NULL,
[produce_part_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[produce_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[produce_qty] [float] NULL,
[produce_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[produce_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[produce_conv_factor] [float] NULL,
[produce_prod_ext] [int] NULL,
[inv_std_cost] [float] NULL,
[produce_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [float] NULL,
[direct_dolrs] [float] NULL,
[ovhd_dolrs] [float] NULL,
[util_dolrs] [float] NULL,
[std_direct_dolrs] [float] NULL,
[std_ovhd_dolrs] [float] NULL,
[std_util_dolrs] [float] NULL,
[pl_qty] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_prodvar] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_prodvar] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_prodvar] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_prodvar] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_prodvar] TO [public]
GO
