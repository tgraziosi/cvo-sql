CREATE TABLE [dbo].[rpt_invcyclecnt]
(
[cycle_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cycle_date] [datetime] NULL,
[lot] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (18, 0) NULL,
[hold_qty] [decimal] (18, 0) NULL,
[rank_class] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invcyclecnt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invcyclecnt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invcyclecnt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invcyclecnt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invcyclecnt] TO [public]
GO
