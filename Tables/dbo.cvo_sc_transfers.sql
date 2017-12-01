CREATE TABLE [dbo].[cvo_sc_transfers]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[release_date] [datetime] NULL,
[brand] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isActive] [tinyint] NULL CONSTRAINT [DF__cvo_sc_tr__isAct__44130A98] DEFAULT ('1'),
[transfer_date] [datetime] NULL,
[template_group] [int] NULL CONSTRAINT [DF__cvo_sc_tr__templ__39B577B6] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_sc_transfers] ADD CONSTRAINT [PK__cvo_sc_transfers__431EE65F] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
