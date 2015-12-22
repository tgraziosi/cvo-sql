CREATE TABLE [dbo].[ibtax]
(
[timestamp] [timestamp] NULL,
[id] [uniqueidentifier] NULL,
[sequence_id] [int] NULL,
[tax_type_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_gross] [decimal] (20, 8) NULL,
[amt_taxable] [decimal] (20, 8) NULL,
[amt_tax] [decimal] (20, 8) NULL,
[create_date] [datetime] NULL,
[create_username] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_change_date] [datetime] NULL,
[last_change_username] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[balance_oper] [decimal] (20, 8) NULL,
[rate_oper] [decimal] (20, 8) NULL,
[oper_currency] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[balance_home] [decimal] (20, 8) NULL,
[rate_home] [decimal] (20, 8) NULL,
[home_currency] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ibtax_i1] ON [dbo].[ibtax] ([id], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ibtax] TO [public]
GO
GRANT SELECT ON  [dbo].[ibtax] TO [public]
GO
GRANT INSERT ON  [dbo].[ibtax] TO [public]
GO
GRANT DELETE ON  [dbo].[ibtax] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibtax] TO [public]
GO
