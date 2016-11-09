CREATE TABLE [dbo].[cvo_carts_config]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[cart_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart_id] [int] NULL,
[cart_ip] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart_port] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL,
[modified_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_carts_config] ADD CONSTRAINT [PK__cvo_carts_config__56302425] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
