CREATE TABLE [dbo].[ibdet]
(
[timestamp] [timestamp] NULL,
[id] [uniqueidentifier] NULL,
[sequence_id] [int] NULL,
[org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [decimal] (20, 8) NULL,
[currency_code] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_description] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reconciled_flag] [int] NULL,
[create_date] [datetime] NOT NULL,
[create_username] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[balance_oper] [decimal] (20, 8) NULL,
[rate_oper] [decimal] (20, 8) NULL,
[oper_currency] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[balance_home] [decimal] (20, 8) NULL,
[rate_home] [decimal] (20, 8) NULL,
[home_currency] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dispute_flag] [smallint] NOT NULL,
[dispute_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ibdet_i1] ON [dbo].[ibdet] ([id], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ibdet] TO [public]
GO
GRANT SELECT ON  [dbo].[ibdet] TO [public]
GO
GRANT INSERT ON  [dbo].[ibdet] TO [public]
GO
GRANT DELETE ON  [dbo].[ibdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibdet] TO [public]
GO
