CREATE TABLE [dbo].[aptrxtax]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_tax] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aptrxtax_ind_0] ON [dbo].[aptrxtax] ([trx_ctrl_num], [trx_type], [tax_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aptrxtax] TO [public]
GO
GRANT SELECT ON  [dbo].[aptrxtax] TO [public]
GO
GRANT INSERT ON  [dbo].[aptrxtax] TO [public]
GO
GRANT DELETE ON  [dbo].[aptrxtax] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptrxtax] TO [public]
GO
