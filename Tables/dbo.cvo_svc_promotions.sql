CREATE TABLE [dbo].[cvo_svc_promotions]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[program_id] [int] NULL,
[promo_level] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_order] [int] NULL,
[max_order] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_promotions] ADD CONSTRAINT [PK__cvo_svc_promotio__02EF52B1] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_promotions] ADD CONSTRAINT [fk_svc_prom_program] FOREIGN KEY ([program_id]) REFERENCES [dbo].[cvo_svc_programs] ([program_id])
GO
