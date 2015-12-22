CREATE TABLE [dbo].[rpt_ibifc]
(
[id] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NULL,
[date_applied] [datetime] NULL,
[trx_type_desc] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[controlling_org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[detail_org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NULL,
[currency_code] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recipient_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[originator_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_payable_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_expense_code] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state_flag] [int] NULL,
[link1] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[link2] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[link3] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_flag] [smallint] NULL,
[hold_desc] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ibifc] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ibifc] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ibifc] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ibifc] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ibifc] TO [public]
GO
