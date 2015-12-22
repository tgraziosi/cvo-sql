CREATE TABLE [dbo].[rpt_arnonardet]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price] [float] NOT NULL,
[extended_price] [float] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax] [float] NOT NULL,
[qty_shipped] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arnonardet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arnonardet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arnonardet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arnonardet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arnonardet] TO [public]
GO
