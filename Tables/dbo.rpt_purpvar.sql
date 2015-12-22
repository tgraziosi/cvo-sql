CREATE TABLE [dbo].[rpt_purpvar]
(
[item_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [float] NULL,
[r_unit_cost] [float] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_unit_cost] [float] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[receipt_no] [int] NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[std_cost] [float] NULL,
[std_direct_dolrs] [float] NULL,
[std_ovhd_dolrs] [float] NULL,
[std_util_dolrs] [float] NULL,
[conv_factor] [float] NULL,
[unit_measure] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_purpvar] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_purpvar] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_purpvar] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_purpvar] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_purpvar] TO [public]
GO
