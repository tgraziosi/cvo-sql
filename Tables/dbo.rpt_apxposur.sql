CREATE TABLE [dbo].[rpt_apxposur]
(
[trx_type] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_due] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[amount] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_rate] [float] NOT NULL,
[asof_rate] [float] NOT NULL,
[rate_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_end_date] [int] NOT NULL,
[dt_applied] [datetime] NULL,
[dt_due] [datetime] NULL,
[group_by1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_by2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_by1_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apxposur] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apxposur] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apxposur] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apxposur] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apxposur] TO [public]
GO
