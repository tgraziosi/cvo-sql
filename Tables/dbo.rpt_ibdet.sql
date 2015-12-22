CREATE TABLE [dbo].[rpt_ibdet]
(
[id] [nvarchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NULL,
[amount] [decimal] (20, 8) NULL,
[doc_description] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reconciled_flag] [int] NULL,
[reference_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance_oper] [decimal] (20, 8) NULL,
[rate_oper] [decimal] (20, 8) NULL,
[oper_currency] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance_home] [decimal] (20, 8) NULL,
[rate_home] [decimal] (20, 8) NULL,
[home_currency] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dispute_flag] [smallint] NOT NULL,
[dispute_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ibdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ibdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ibdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ibdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ibdet] TO [public]
GO
