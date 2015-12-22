CREATE TABLE [dbo].[arinptax]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_final_tax] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arinptax_ind_0] ON [dbo].[arinptax] ([trx_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinptax_ind_1] ON [dbo].[arinptax] ([trx_ctrl_num], [trx_type], [tax_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arinptax] TO [public]
GO
GRANT SELECT ON  [dbo].[arinptax] TO [public]
GO
GRANT INSERT ON  [dbo].[arinptax] TO [public]
GO
GRANT DELETE ON  [dbo].[arinptax] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinptax] TO [public]
GO
