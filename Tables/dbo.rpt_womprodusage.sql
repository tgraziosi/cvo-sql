CREATE TABLE [dbo].[rpt_womprodusage]
(
[prod_no] [int] NULL,
[prod_ext] [int] NULL,
[prod_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_no] [int] NULL,
[employee_key] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans_date] [datetime] NULL,
[used_qty] [decimal] (20, 8) NULL,
[pieces] [decimal] (20, 8) NULL,
[shift] [int] NULL,
[scraps_pcs] [decimal] (20, 8) NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_womprodusage] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_womprodusage] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_womprodusage] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_womprodusage] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_womprodusage] TO [public]
GO
