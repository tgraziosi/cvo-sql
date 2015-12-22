CREATE TABLE [dbo].[rpt_ap99tthdr]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[desc_1099] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[year] [smallint] NULL,
[amount] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ap99tthdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ap99tthdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ap99tthdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ap99tthdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ap99tthdr] TO [public]
GO
