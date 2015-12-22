CREATE TABLE [dbo].[iblink]
(
[timestamp] [timestamp] NOT NULL,
[id] [uniqueidentifier] NOT NULL,
[sequence_id] [int] NOT NULL,
[trx_type] [int] NOT NULL,
[source_trx_ctrl_num] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_sequence_id] [int] NOT NULL,
[source_url] [nvarchar] (2048) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_urn] [nvarchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_id] [int] NOT NULL,
[source_po_no] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_order_no] [int] NOT NULL,
[source_ext] [int] NOT NULL,
[source_line] [int] NOT NULL,
[trx_ctrl_num] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[create_date] [datetime] NULL,
[create_username] [nvarchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [nvarchar] (512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [iblink_i1] ON [dbo].[iblink] ([id], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[iblink] TO [public]
GO
GRANT SELECT ON  [dbo].[iblink] TO [public]
GO
GRANT INSERT ON  [dbo].[iblink] TO [public]
GO
GRANT DELETE ON  [dbo].[iblink] TO [public]
GO
GRANT UPDATE ON  [dbo].[iblink] TO [public]
GO
