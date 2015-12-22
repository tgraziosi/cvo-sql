CREATE TABLE [dbo].[rpt_apinpstl]
(
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hold_flag] [smallint] NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state_flag] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apinpstl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apinpstl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apinpstl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apinpstl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apinpstl] TO [public]
GO
