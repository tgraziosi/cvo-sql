CREATE TABLE [dbo].[rpt_appuracd]
(
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [datetime] NULL,
[date_applied] [datetime] NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[charge] [float] NOT NULL,
[payment] [float] NOT NULL,
[adjust] [float] NOT NULL,
[rate] [float] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appuracd] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appuracd] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appuracd] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appuracd] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appuracd] TO [public]
GO
