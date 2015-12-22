CREATE TABLE [dbo].[ibifc_all]
(
[timestamp] [timestamp] NULL,
[id] [uniqueidentifier] NULL,
[date_entered] [datetime] NULL,
[date_applied] [datetime] NULL,
[trx_type] [int] NULL,
[controlling_org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[detail_org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [decimal] (20, 8) NULL,
[currency_code] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[recipient_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[originator_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_payable_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_expense_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state_flag] [int] NULL,
[process_ctrl_num] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[link1] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[link2] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[link3] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[username] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_flag] [smallint] NULL,
[hold_desc] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ibifc_all_i1] ON [dbo].[ibifc_all] ([id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ibifc_all] TO [public]
GO
GRANT SELECT ON  [dbo].[ibifc_all] TO [public]
GO
GRANT INSERT ON  [dbo].[ibifc_all] TO [public]
GO
GRANT DELETE ON  [dbo].[ibifc_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibifc_all] TO [public]
GO
