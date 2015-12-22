CREATE TABLE [dbo].[rpt_glebhold]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[ebas_key] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_doc] [int] NULL,
[amt_tax] [float] NULL,
[date_applied] [int] NULL,
[amount] [float] NULL,
[din] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_date] [int] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glebhold] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glebhold] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glebhold] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glebhold] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glebhold] TO [public]
GO
