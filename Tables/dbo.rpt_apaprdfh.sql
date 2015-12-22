CREATE TABLE [dbo].[rpt_apaprdfh]
(
[timestamp] [timestamp] NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_min] [float] NOT NULL,
[po_flag] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vouch_flag] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[check_flag] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apaprdfh] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apaprdfh] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apaprdfh] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apaprdfh] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apaprdfh] TO [public]
GO
