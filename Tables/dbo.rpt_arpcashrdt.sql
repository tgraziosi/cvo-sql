CREATE TABLE [dbo].[rpt_arpcashrdt]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_flag] [smallint] NOT NULL,
[sub_apply_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_apply_type] [smallint] NOT NULL,
[date_aging] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[inv_amt_wr_off] [real] NOT NULL,
[inv_amt_disc_taken] [real] NOT NULL,
[inv_amt_applied] [real] NOT NULL,
[gain_home] [real] NOT NULL,
[gain_oper] [real] NOT NULL,
[inv_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[trx_type] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpcashrdt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpcashrdt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpcashrdt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpcashrdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpcashrdt] TO [public]
GO
