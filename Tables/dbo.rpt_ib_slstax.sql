CREATE TABLE [dbo].[rpt_ib_slstax]
(
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_auth_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_auth_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_applied] [datetime] NOT NULL,
[date_doc] [datetime] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_gross] [float] NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[group_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_by_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate] [float] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NOT NULL,
[taxpayer_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ib_slstax] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ib_slstax] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ib_slstax] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ib_slstax] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ib_slstax] TO [public]
GO
