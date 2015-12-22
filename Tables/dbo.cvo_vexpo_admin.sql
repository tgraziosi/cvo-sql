CREATE TABLE [dbo].[cvo_vexpo_admin]
(
[user_login] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[view_all] [tinyint] NULL CONSTRAINT [DF__cvo_vexpo__view___1DE30E45] DEFAULT ((0)),
[cross_terr_orders] [tinyint] NULL CONSTRAINT [DF__cvo_vexpo__cross__1ED7327E] DEFAULT ((0))
) ON [PRIMARY]
GO
