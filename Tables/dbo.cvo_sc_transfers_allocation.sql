CREATE TABLE [dbo].[cvo_sc_transfers_allocation]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[transfer_id] [int] NULL,
[template_id] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sku] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[color_family] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alloc_date] [datetime] NULL,
[template_group] [int] NULL CONSTRAINT [DF__cvo_sc_tr__templ__3AA99BEF] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_sc_transfers_allocation] ADD CONSTRAINT [PK__cvo_sc_transfers__45FB530A] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
