CREATE TABLE [dbo].[rpt_ibtax]
(
[id] [nvarchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NULL,
[tax_type_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_gross] [decimal] (20, 8) NULL,
[amt_taxable] [decimal] (20, 8) NULL,
[amt_tax] [decimal] (20, 8) NULL,
[nat_cur_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance_oper] [decimal] (20, 8) NULL,
[rate_oper] [decimal] (20, 8) NULL,
[oper_currency] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance_home] [decimal] (20, 8) NULL,
[rate_home] [decimal] (20, 8) NULL,
[home_currency] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ibtax] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ibtax] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ibtax] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ibtax] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ibtax] TO [public]
GO
