CREATE TABLE [dbo].[esc_cust_pricing]
(
[Cust#] [float] NULL,
[name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Group/Brand] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STYLE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ITEM] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Start] [datetime] NULL,
[typ] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt] [float] NULL,
[ITEM1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release date] [datetime] NULL,
[disc] [float] NULL,
[phase out] [float] NULL,
[TAKE OVER -YES OR NO] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[esc_cust_pricing] TO [public]
GO
GRANT INSERT ON  [dbo].[esc_cust_pricing] TO [public]
GO
GRANT DELETE ON  [dbo].[esc_cust_pricing] TO [public]
GO
GRANT UPDATE ON  [dbo].[esc_cust_pricing] TO [public]
GO
