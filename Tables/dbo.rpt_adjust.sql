CREATE TABLE [dbo].[rpt_adjust]
(
[issue_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_from] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avg_cost] [float] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[issue_date] [datetime] NULL,
[note] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [float] NULL,
[inventory] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direction] [int] NULL,
[date_expires] [datetime] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direct_dolrs] [float] NULL,
[ovhd_dolrs] [float] NULL,
[util_dolrs] [float] NULL,
[labor] [float] NULL,
[account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group1] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_adjust] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_adjust] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_adjust] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_adjust] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_adjust] TO [public]
GO
