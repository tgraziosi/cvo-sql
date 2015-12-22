CREATE TABLE [dbo].[rpt_apvdspch]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NULL,
[user_id] [smallint] NOT NULL,
[cash_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apvdspch] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apvdspch] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apvdspch] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apvdspch] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apvdspch] TO [public]
GO
