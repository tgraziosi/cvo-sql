CREATE TABLE [dbo].[cmmandtl]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_document] [int] NOT NULL,
[trx_type_cls] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount_natural] [float] NOT NULL,
[amount_home] [float] NULL,
[auto_rec_flag] [smallint] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cmmandtl_ind_1] ON [dbo].[cmmandtl] ([trx_ctrl_num], [trx_type], [doc_ctrl_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmmandtl_ind_0] ON [dbo].[cmmandtl] ([trx_ctrl_num], [trx_type], [doc_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmmandtl] TO [public]
GO
GRANT SELECT ON  [dbo].[cmmandtl] TO [public]
GO
GRANT INSERT ON  [dbo].[cmmandtl] TO [public]
GO
GRANT DELETE ON  [dbo].[cmmandtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmmandtl] TO [public]
GO
