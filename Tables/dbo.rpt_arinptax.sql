CREATE TABLE [dbo].[rpt_arinptax]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_final_tax] [float] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arinptax] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arinptax] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arinptax] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arinptax] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arinptax] TO [public]
GO
