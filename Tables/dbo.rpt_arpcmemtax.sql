CREATE TABLE [dbo].[rpt_arpcmemtax]
(
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_tax] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpcmemtax] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpcmemtax] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpcmemtax] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpcmemtax] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpcmemtax] TO [public]
GO
