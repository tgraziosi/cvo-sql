CREATE TABLE [dbo].[rpt_arpwroffDetail]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_due] [int] NOT NULL,
[amt_tot_chg] [real] NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_paid_to_date] [real] NOT NULL,
[days_past] [int] NOT NULL,
[balance] [real] NOT NULL,
[rate_home] [real] NOT NULL,
[nat_cur_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpwroffDetail] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpwroffDetail] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpwroffDetail] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpwroffDetail] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpwroffDetail] TO [public]
GO
