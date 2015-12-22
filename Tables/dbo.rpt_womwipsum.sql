CREATE TABLE [dbo].[rpt_womwipsum]
(
[prod_no] [int] NULL,
[prod_ext] [int] NULL,
[prod_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_sch_qty] [decimal] (20, 0) NULL,
[prod_qty] [decimal] (20, 0) NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [decimal] (20, 0) NULL,
[direct_dolrs] [decimal] (20, 0) NULL,
[ovhd_dolrs] [decimal] (20, 0) NULL,
[util_dolrs] [decimal] (20, 0) NULL,
[qty] [decimal] (20, 0) NULL,
[costmeth] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_womwipsum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_womwipsum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_womwipsum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_womwipsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_womwipsum] TO [public]
GO
