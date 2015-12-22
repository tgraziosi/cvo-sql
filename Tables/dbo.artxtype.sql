CREATE TABLE [dbo].[artxtype]
(
[timestamp] [timestamp] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_auth_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_tax] [float] NOT NULL,
[prc_flag] [smallint] NOT NULL,
[prc_type] [smallint] NOT NULL,
[cents_code_flag] [smallint] NOT NULL,
[cents_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_based_type] [smallint] NOT NULL,
[tax_included_flag] [smallint] NOT NULL,
[modify_base_prc] [float] NOT NULL,
[base_range_flag] [smallint] NOT NULL,
[base_range_type] [smallint] NOT NULL,
[base_taxed_type] [smallint] NOT NULL,
[min_base_amt] [float] NOT NULL,
[max_base_amt] [float] NOT NULL,
[tax_range_flag] [smallint] NOT NULL,
[tax_range_type] [smallint] NOT NULL,
[min_tax_amt] [float] NOT NULL,
[max_tax_amt] [float] NOT NULL,
[sales_tax_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ap_tax_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ar_tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_flag] [smallint] NOT NULL,
[recoverable_flag] [smallint] NULL CONSTRAINT [DF__artxtype__recove__1A2A23F8] DEFAULT ((1)),
[gl_internal_tax_account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_connect_flag] [smallint] NULL CONSTRAINT [DF__artxtype__tax_co__31779DA4] DEFAULT ((0)),
[tc_global] [smallint] NULL CONSTRAINT [DF__artxtype__tc_glo__326BC1DD] DEFAULT ((0)),
[tc_juristype] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artxtype__tc_jur__335FE616] DEFAULT (''),
[tc_juriscode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artxtype__tc_jur__34540A4F] DEFAULT (''),
[external_tax_type_code] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artxtype__extern__35482E88] DEFAULT ('')
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [artxtype_ind_0] ON [dbo].[artxtype] ([tax_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artxtype] TO [public]
GO
GRANT SELECT ON  [dbo].[artxtype] TO [public]
GO
GRANT INSERT ON  [dbo].[artxtype] TO [public]
GO
GRANT DELETE ON  [dbo].[artxtype] TO [public]
GO
GRANT UPDATE ON  [dbo].[artxtype] TO [public]
GO
