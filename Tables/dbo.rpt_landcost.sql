CREATE TABLE [dbo].[rpt_landcost]
(
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_dt] [datetime] NULL,
[amt_net] [float] NULL,
[amt_extended] [float] NULL,
[qty_received] [float] NULL,
[amt_freight] [float] NULL,
[amt_tax] [float] NULL,
[amt_misc] [float] NULL,
[amt_discount] [float] NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lc_alloc_total] [money] NULL,
[gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[allocation_no] [int] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_landcost] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_landcost] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_landcost] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_landcost] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_landcost] TO [public]
GO
