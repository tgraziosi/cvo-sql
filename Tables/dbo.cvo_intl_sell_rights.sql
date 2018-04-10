CREATE TABLE [dbo].[cvo_intl_sell_rights]
(
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pa] [int] NULL CONSTRAINT [DF__cvo_intl_sel__pa__23120980] DEFAULT ((0)),
[id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_intl_sell_rights] ADD CONSTRAINT [PK__cvo_intl_sell_ri__221DE547] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_isr_brand] ON [dbo].[cvo_intl_sell_rights] ([brand]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_isr_cntry] ON [dbo].[cvo_intl_sell_rights] ([country_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_intl_sell_rights] TO [public]
GO
