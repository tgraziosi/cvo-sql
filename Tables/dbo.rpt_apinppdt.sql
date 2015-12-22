CREATE TABLE [dbo].[rpt_apinppdt]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[amt_applied] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_flag] [smallint] NOT NULL,
[payment_hold_flag] [smallint] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vo_amt_applied] [float] NOT NULL,
[vo_amt_disc_taken] [float] NOT NULL,
[gain_home] [float] NOT NULL,
[gain_oper] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_precision] [smallint] NOT NULL,
[home_amt_applied] [float] NOT NULL,
[home_amt_disc_taken] [float] NOT NULL,
[home_vo_amt_applied] [float] NOT NULL,
[home_vo_amt_disc_taken] [float] NOT NULL,
[oper_amt_applied] [float] NOT NULL,
[oper_amt_disc_taken] [float] NOT NULL,
[oper_vo_amt_applied] [float] NOT NULL,
[oper_vo_amt_disc_taken] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apinppdt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apinppdt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apinppdt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apinppdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apinppdt] TO [public]
GO
