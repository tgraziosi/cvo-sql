CREATE TABLE [dbo].[artrxtax]
(
[timestamp] [timestamp] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_tax] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [artrxtax_ind_0] ON [dbo].[artrxtax] ([tax_type_code], [doc_ctrl_num], [trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artrxtax] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxtax] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxtax] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxtax] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxtax] TO [public]
GO
