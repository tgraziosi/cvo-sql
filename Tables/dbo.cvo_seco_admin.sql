CREATE TABLE [dbo].[cvo_seco_admin]
(
[user_login] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[view_all] [tinyint] NULL CONSTRAINT [DF__cvo_seco___view___72B426DE] DEFAULT ((0)),
[cross_terr_orders] [tinyint] NULL CONSTRAINT [DF__cvo_seco___cross__73A84B17] DEFAULT ((0))
) ON [PRIMARY]
GO
