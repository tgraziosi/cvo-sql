CREATE TABLE [dbo].[gltcrecon]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[app_id] [int] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[remote_doc_id] [bigint] NULL,
[remote_state] [smallint] NOT NULL,
[reconciled_flag] [smallint] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[remote_amt_gross] [float] NOT NULL,
[remote_amt_tax] [float] NOT NULL,
[customervendor_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_doc] [int] NULL,
[reconciliated_date] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [gltcrecon_idx1] ON [dbo].[gltcrecon] ([remote_doc_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [gltcrecon_ind_0] ON [dbo].[gltcrecon] ([trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltcrecon] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcrecon] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcrecon] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcrecon] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcrecon] TO [public]
GO
