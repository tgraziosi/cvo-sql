CREATE TABLE [dbo].[rpt_eppohdr]
(
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_id] [smallint] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[groupby] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_eppohdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_eppohdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_eppohdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_eppohdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_eppohdr] TO [public]
GO
