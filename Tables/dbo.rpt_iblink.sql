CREATE TABLE [dbo].[rpt_iblink]
(
[id] [nvarchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[trx_type] [int] NOT NULL,
[source_trx_ctrl_num] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_sequence_id] [int] NOT NULL,
[source_url] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_urn] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_id] [int] NOT NULL,
[source_po_no] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_order_no] [int] NOT NULL,
[source_ext] [int] NOT NULL,
[source_line] [int] NOT NULL,
[trx_ctrl_num] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_iblink] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_iblink] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_iblink] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_iblink] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_iblink] TO [public]
GO
