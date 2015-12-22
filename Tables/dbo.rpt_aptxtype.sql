CREATE TABLE [dbo].[rpt_aptxtype]
(
[timestamp] [timestamp] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_auth_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ar_tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_tax] [float] NOT NULL,
[prc_flag] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prc_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cents_code_flag] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cents_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_based_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_included_flag] [smallint] NOT NULL,
[modify_base_prc] [float] NOT NULL,
[base_range_flag] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[base_range_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[base_taxed_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[min_base_amt] [float] NOT NULL,
[max_base_amt] [float] NOT NULL,
[tax_range_flag] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_range_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[min_tax_amt] [float] NOT NULL,
[max_tax_amt] [float] NOT NULL,
[vat_flag] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[gl_internal_tax_account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recoverable_flag] [int] NOT NULL,
[sales_tax_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aptxtype] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aptxtype] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aptxtype] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aptxtype] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aptxtype] TO [public]
GO
