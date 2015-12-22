CREATE TABLE [dbo].[aptrxtaxdtl]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[trx_type] [int] NOT NULL,
[tax_sequence_id] [int] NOT NULL,
[detail_sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_final_tax] [float] NOT NULL,
[recoverable_flag] [int] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aptrxtaxdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[aptrxtaxdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[aptrxtaxdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[aptrxtaxdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptrxtaxdtl] TO [public]
GO
