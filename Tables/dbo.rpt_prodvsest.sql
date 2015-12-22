CREATE TABLE [dbo].[rpt_prodvsest]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [int] NULL,
[prod_ext] [int] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[est_no] [int] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[est_matl_dolrs] [decimal] (20, 0) NULL,
[est_labr_dolrs] [decimal] (20, 0) NULL,
[plan_matl_dolrs] [decimal] (20, 0) NULL,
[plan_labr_dolrs] [decimal] (20, 0) NULL,
[act_matl_dolrs] [decimal] (20, 0) NULL,
[act_labr_dolrs] [decimal] (20, 0) NULL,
[act_matl_std] [decimal] (20, 0) NULL,
[act_labr_std] [decimal] (20, 0) NULL,
[est_price] [decimal] (20, 0) NULL,
[est_qty] [decimal] (20, 0) NULL,
[c_prod] [int] NULL,
[c_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[c_stat] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bdate] [datetime] NULL,
[edate] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_prodvsest] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_prodvsest] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_prodvsest] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_prodvsest] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_prodvsest] TO [public]
GO
