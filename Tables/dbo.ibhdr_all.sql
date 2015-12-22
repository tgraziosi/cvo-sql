CREATE TABLE [dbo].[ibhdr_all]
(
[timestamp] [timestamp] NULL,
[id] [uniqueidentifier] NULL,
[trx_ctrl_num] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NOT NULL,
[date_applied] [datetime] NOT NULL,
[trx_type] [int] NULL,
[controlling_org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[detail_org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [decimal] (20, 8) NOT NULL,
[currency_code] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_description] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_date] [datetime] NOT NULL,
[create_username] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ibhdr_all_i1] ON [dbo].[ibhdr_all] ([id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ibhdr_all_i2] ON [dbo].[ibhdr_all] ([trx_type], [trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ibhdr_all] TO [public]
GO
GRANT SELECT ON  [dbo].[ibhdr_all] TO [public]
GO
GRANT INSERT ON  [dbo].[ibhdr_all] TO [public]
GO
GRANT DELETE ON  [dbo].[ibhdr_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibhdr_all] TO [public]
GO
