CREATE TABLE [dbo].[rpt_artrxdtl]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_shipped] [float] NOT NULL,
[unit_price] [float] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_artrxdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_artrxdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_artrxdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_artrxdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_artrxdtl] TO [public]
GO
