CREATE TABLE [dbo].[rpt_amrtvch]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_net] [float] NOT NULL,
[hits_fac] [tinyint] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amrtvch] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amrtvch] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amrtvch] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amrtvch] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amrtvch] TO [public]
GO
