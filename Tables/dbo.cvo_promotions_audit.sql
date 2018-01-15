CREATE TABLE [dbo].[cvo_promotions_audit]
(
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[action] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[what_updated] [varchar] (2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_updated] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[when_updated] [datetime] NOT NULL,
[id] [int] NOT NULL IDENTITY(1, 1),
[where_updated] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_promotions_audit] ADD CONSTRAINT [PK_cvo_promotions_audit] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
