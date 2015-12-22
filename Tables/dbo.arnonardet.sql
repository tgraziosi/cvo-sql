CREATE TABLE [dbo].[arnonardet]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price] [float] NOT NULL,
[extended_price] [float] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax] [float] NOT NULL,
[qty_shipped] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_NONAR] ON [dbo].[arnonardet] ([trx_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arnonardet] TO [public]
GO
GRANT SELECT ON  [dbo].[arnonardet] TO [public]
GO
GRANT INSERT ON  [dbo].[arnonardet] TO [public]
GO
GRANT DELETE ON  [dbo].[arnonardet] TO [public]
GO
GRANT UPDATE ON  [dbo].[arnonardet] TO [public]
GO
