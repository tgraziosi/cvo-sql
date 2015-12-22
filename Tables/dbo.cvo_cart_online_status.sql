CREATE TABLE [dbo].[cvo_cart_online_status]
(
[cart_no] [tinyint] NULL,
[isOnline] [tinyint] NULL CONSTRAINT [DF__cvo_cart___isOnl__654451D0] DEFAULT ((0))
) ON [PRIMARY]
GO
