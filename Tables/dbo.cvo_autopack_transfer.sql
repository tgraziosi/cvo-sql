CREATE TABLE [dbo].[cvo_autopack_transfer]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[xfer_no] [int] NOT NULL,
[proc_user_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[processed] [smallint] NOT NULL,
[processed_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_autopack_transfer_inx02] ON [dbo].[cvo_autopack_transfer] ([processed]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_autopack_transfer_pk] ON [dbo].[cvo_autopack_transfer] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_autopack_transfer_inx01] ON [dbo].[cvo_autopack_transfer] ([xfer_no], [processed]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_autopack_transfer] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_autopack_transfer] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_autopack_transfer] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_autopack_transfer] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_autopack_transfer] TO [public]
GO
