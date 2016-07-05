CREATE TABLE [dbo].[cvo_ifp_config]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[tag] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[threshold] [int] NOT NULL,
[order_thru_date] [datetime] NULL,
[asofdate] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [pk_ifp_config_idx] ON [dbo].[cvo_ifp_config] ([id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_ifp_config] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_ifp_config] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ifp_config] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ifp_config] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ifp_config] TO [public]
GO
