CREATE TABLE [dbo].[rpt_arstlhdr]
(
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reporting_curr] [smallint] NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NULL,
[date_applied] [datetime] NULL,
[doc_count_expected] [int] NOT NULL,
[doc_count_entered] [int] NOT NULL,
[doc_sum_expected] [float] NOT NULL,
[doc_sum_entered] [float] NOT NULL,
[cr_total] [float] NOT NULL,
[oacr_total] [float] NOT NULL,
[cm_total] [float] NOT NULL,
[inv_total] [float] NOT NULL,
[disc_total] [float] NOT NULL,
[wroff_total] [float] NOT NULL,
[onacct_total] [float] NOT NULL,
[gain_total] [float] NOT NULL,
[loss_total] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arstlhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arstlhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arstlhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arstlhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arstlhdr] TO [public]
GO
