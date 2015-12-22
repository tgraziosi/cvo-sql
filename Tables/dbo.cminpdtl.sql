CREATE TABLE [dbo].[cminpdtl]
(
[timestamp] [timestamp] NOT NULL,
[rec_id] [int] NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_document] [int] NOT NULL,
[date_cleared] [int] NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount_book] [float] NOT NULL,
[reconciled_flag] [smallint] NOT NULL,
[closed_flag] [smallint] NOT NULL,
[void_flag] [smallint] NOT NULL,
[date_applied] [int] NOT NULL,
[cleared_type] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cminpdtl_ind_0] ON [dbo].[cminpdtl] ([cash_acct_code], [trx_ctrl_num], [doc_ctrl_num], [trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cminpdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[cminpdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[cminpdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[cminpdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cminpdtl] TO [public]
GO
