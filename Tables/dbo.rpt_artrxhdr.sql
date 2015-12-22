CREATE TABLE [dbo].[rpt_artrxhdr]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_posted] [int] NOT NULL,
[amt_gross] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_trx_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[flag_det] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[chargeref] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[old_cb_status_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_cb_status_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[old_cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[old_store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[old_cb_resp_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_cb_resp_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_artrxhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_artrxhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_artrxhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_artrxhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_artrxhdr] TO [public]
GO
