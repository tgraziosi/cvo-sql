CREATE TABLE [dbo].[rpt_apstlhdr]
(
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reporting_curr] [smallint] NULL,
[date_entered] [datetime] NULL,
[date_applied] [datetime] NULL,
[pyt_total] [float] NOT NULL,
[oapyt_total] [float] NOT NULL,
[oadm_total] [float] NOT NULL,
[pyt_oa_total] [float] NOT NULL,
[disc_total] [float] NOT NULL,
[gain_total] [float] NOT NULL,
[loss_total] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apstlhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apstlhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apstlhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apstlhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apstlhdr] TO [public]
GO
