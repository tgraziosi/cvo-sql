CREATE TABLE [dbo].[cvo_sc_transfers_templates]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[template] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_date] [datetime] NULL CONSTRAINT [DF__cvo_sc_tr__modif__54146837] DEFAULT (getdate()),
[template_group] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_sc_transfers_templates] ADD CONSTRAINT [PK__cvo_sc_transfers__532043FE] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
