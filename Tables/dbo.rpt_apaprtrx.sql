CREATE TABLE [dbo].[rpt_apaprtrx]
(
[user_id] [smallint] NOT NULL,
[group_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NOT NULL,
[date_assigned] [datetime] NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id_approver] [smallint] NOT NULL,
[user_name_approver] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apaprtrx] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apaprtrx] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apaprtrx] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apaprtrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apaprtrx] TO [public]
GO
