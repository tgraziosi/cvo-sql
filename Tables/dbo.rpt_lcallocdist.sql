CREATE TABLE [dbo].[rpt_lcallocdist]
(
[allocation_no] [int] NULL,
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[receipt_no] [int] NULL,
[cost_to_cd] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost_to_amt] [decimal] (20, 8) NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_date] [datetime] NULL,
[sort_by] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_lcallocdist] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_lcallocdist] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_lcallocdist] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_lcallocdist] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_lcallocdist] TO [public]
GO
