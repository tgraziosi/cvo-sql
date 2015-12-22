CREATE TABLE [dbo].[rpt_apsubledgerdet]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[beginning_bal] [float] NOT NULL,
[debit] [float] NOT NULL,
[credit] [float] NOT NULL,
[ending_bal] [float] NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[amount] [float] NOT NULL,
[date_applied] [datetime] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [datetime] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apsubledgerdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apsubledgerdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apsubledgerdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apsubledgerdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apsubledgerdet] TO [public]
GO
