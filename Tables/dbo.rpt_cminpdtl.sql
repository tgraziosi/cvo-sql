CREATE TABLE [dbo].[rpt_cminpdtl]
(
[trx_type] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_document] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount_book] [float] NOT NULL,
[reconciled_flag] [smallint] NULL,
[closed_flag] [smallint] NULL,
[void_flag] [smallint] NOT NULL,
[date_cleared] [int] NULL,
[document1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cleared_type] [smallint] NOT NULL,
[cleared_desc] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cminpdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cminpdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cminpdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cminpdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cminpdtl] TO [public]
GO
