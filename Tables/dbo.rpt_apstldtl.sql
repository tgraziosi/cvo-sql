CREATE TABLE [dbo].[rpt_apstldtl]
(
[voucher_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [datetime] NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[deb_exc_rate] [float] NOT NULL,
[home_exc_rate] [float] NOT NULL,
[cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[deb_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[home_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_applied] [float] NOT NULL,
[deb_amt_applied] [float] NOT NULL,
[home_amt_applied] [float] NOT NULL,
[amt_disc] [float] NOT NULL,
[home_amt_disc] [float] NOT NULL,
[home_oper_gain_loss] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apstldtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apstldtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apstldtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apstldtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apstldtl] TO [public]
GO
