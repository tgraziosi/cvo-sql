CREATE TABLE [dbo].[cvo_svc_orders]
(
[code] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[brand] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[master_sku] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sku] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_color] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_size] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_price] [float] NULL,
[qty] [smallint] NULL CONSTRAINT [DF__cvo_svc_ord__qty__6743D916] DEFAULT ((0)),
[cust_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isActive] [smallint] NULL CONSTRAINT [DF__cvo_svc_o__isAct__1E940E00] DEFAULT ((1))
) ON [PRIMARY]
GO
