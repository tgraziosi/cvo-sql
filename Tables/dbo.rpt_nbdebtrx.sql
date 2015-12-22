CREATE TABLE [dbo].[rpt_nbdebtrx]
(
[net_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_trx_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_doc_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_net] [float] NOT NULL,
[currency_symbol] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_nbdebtrx] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_nbdebtrx] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_nbdebtrx] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_nbdebtrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_nbdebtrx] TO [public]
GO
