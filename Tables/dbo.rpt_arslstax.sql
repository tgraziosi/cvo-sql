CREATE TABLE [dbo].[rpt_arslstax]
(
[tax_auth_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_rate] [float] NOT NULL,
[prc_flag] [smallint] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arslstax] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arslstax] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arslstax] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arslstax] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arslstax] TO [public]
GO
