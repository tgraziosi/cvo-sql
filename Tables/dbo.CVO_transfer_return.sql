CREATE TABLE [dbo].[CVO_transfer_return]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[spid] [int] NOT NULL,
[kit] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[process] [smallint] NOT NULL,
[add_to_inv] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_transfer_return_pk] ON [dbo].[CVO_transfer_return] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_transfer_return_inx01] ON [dbo].[CVO_transfer_return] ([spid]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_transfer_return_inx02] ON [dbo].[CVO_transfer_return] ([spid], [process]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_transfer_return] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_transfer_return] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_transfer_return] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_transfer_return] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_transfer_return] TO [public]
GO
