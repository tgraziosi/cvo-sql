CREATE TABLE [dbo].[cvo_openorder_notes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[order_num] [int] NOT NULL,
[ext] [int] NOT NULL,
[action_rep] [tinyint] NULL CONSTRAINT [DF__cvo_openo__actio__63F5CA45] DEFAULT (NULL),
[action_cus] [tinyint] NULL CONSTRAINT [DF__cvo_openo__actio__64E9EE7E] DEFAULT (NULL),
[note] [varchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_openor__note__65DE12B7] DEFAULT (NULL),
[NoteTime] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_openorder_notes] ADD CONSTRAINT [PK__cvo_openorder_no__6301A60C] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
