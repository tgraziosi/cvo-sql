CREATE TABLE [dbo].[aprptvot]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recoverable_flag] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aprptvot] TO [public]
GO
GRANT SELECT ON  [dbo].[aprptvot] TO [public]
GO
GRANT INSERT ON  [dbo].[aprptvot] TO [public]
GO
GRANT DELETE ON  [dbo].[aprptvot] TO [public]
GO
GRANT UPDATE ON  [dbo].[aprptvot] TO [public]
GO
