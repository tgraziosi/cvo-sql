CREATE TABLE [dbo].[rpt_cmrectrx]
(
[trx_type] [int] NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_document] [int] NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_cleared] [int] NOT NULL,
[amount_book] [float] NOT NULL,
[void_flag] [smallint] NOT NULL,
[flag_void] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmrectrx] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmrectrx] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmrectrx] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmrectrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmrectrx] TO [public]
GO
