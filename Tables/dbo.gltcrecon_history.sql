CREATE TABLE [dbo].[gltcrecon_history]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[app_id] [int] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[remote_doc_id] [bigint] NULL,
[remote_state] [smallint] NOT NULL,
[reconciled_flag] [smallint] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[remote_amt_gross] [float] NOT NULL,
[remote_amt_tax] [float] NOT NULL,
[customervendor_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[reconciliated_date] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [gltcrecon_history_ind_0] ON [dbo].[gltcrecon_history] ([trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltcrecon_history] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcrecon_history] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcrecon_history] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcrecon_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcrecon_history] TO [public]
GO
