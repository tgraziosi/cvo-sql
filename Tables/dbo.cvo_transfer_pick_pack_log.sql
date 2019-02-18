CREATE TABLE [dbo].[cvo_transfer_pick_pack_log]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[log_date] [datetime] NULL,
[xfer_no] [int] NULL,
[log_message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_transfer_pick_pack_log] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_transfer_pick_pack_log] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_transfer_pick_pack_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_transfer_pick_pack_log] TO [public]
GO
