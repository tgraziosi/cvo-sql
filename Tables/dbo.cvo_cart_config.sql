CREATE TABLE [dbo].[cvo_cart_config]
(
[cart1_ip] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart2_ip] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart3_ip] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[config_update] [datetime] NULL CONSTRAINT [DF__cvo_cart___confi__2F68FABA] DEFAULT (getdate()),
[cart1_port] [int] NULL,
[cart2_port] [int] NULL,
[cart3_port] [int] NULL,
[cart4_ip] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart4_port] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart5_ip] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart5_port] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart6_ip] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart6_port] [int] NULL
) ON [PRIMARY]
GO
