CREATE TABLE [dbo].[rpt_vendperf]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[recv_date] [datetime] NULL,
[receipt_no] [int] NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rcv_qty] [money] NULL,
[rtv_qty] [money] NULL,
[scr_qty] [money] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_vendperf] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_vendperf] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_vendperf] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_vendperf] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_vendperf] TO [public]
GO
