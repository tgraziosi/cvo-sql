CREATE TABLE [dbo].[rpt_prod_sched]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sch_date] [datetime] NULL,
[qty_scheduled_orig] [decimal] (20, 8) NULL,
[prod_date] [datetime] NULL,
[qty] [decimal] (20, 8) NULL,
[end_sch_date] [datetime] NULL,
[shift] [int] NULL,
[staging_area] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_prod_sched] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_prod_sched] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_prod_sched] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_prod_sched] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_prod_sched] TO [public]
GO
