CREATE TABLE [dbo].[rpt_invadj]
(
[issue_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_from] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[avg_cost] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[issue_date] [datetime] NOT NULL,
[note] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[inventory] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direction] [int] NOT NULL,
[date_expires] [datetime] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invadj] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invadj] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invadj] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invadj] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invadj] TO [public]
GO
