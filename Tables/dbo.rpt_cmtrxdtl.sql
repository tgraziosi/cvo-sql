CREATE TABLE [dbo].[rpt_cmtrxdtl]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_document] [int] NOT NULL,
[trx_type_cls] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount_natural] [float] NOT NULL,
[auto_rec_flag] [smallint] NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[account_format_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmtrxdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmtrxdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmtrxdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmtrxdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmtrxdtl] TO [public]
GO
