CREATE TABLE [dbo].[rpt_cmbl]
(
[trx_type] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_document] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount_book] [float] NOT NULL,
[void_flag] [smallint] NOT NULL,
[date_cleared] [int] NOT NULL,
[document1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cleared_type] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmbl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmbl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmbl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmbl] TO [public]
GO
