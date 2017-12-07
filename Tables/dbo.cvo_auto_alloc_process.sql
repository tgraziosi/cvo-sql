CREATE TABLE [dbo].[cvo_auto_alloc_process]
(
[process_id] [int] NULL,
[process_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_auto_alloc_process_ind0] ON [dbo].[cvo_auto_alloc_process] ([process_id]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_auto_alloc_process] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_auto_alloc_process] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_auto_alloc_process] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_auto_alloc_process] TO [public]
GO
