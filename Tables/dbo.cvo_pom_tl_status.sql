CREATE TABLE [dbo].[cvo_pom_tl_status]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[asofdate] [datetime] NULL,
[collection] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[color_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pom_date] [datetime] NULL,
[qty_avl] [decimal] (20, 0) NULL,
[in_stock] [decimal] (20, 0) NULL,
[e12_wu] [decimal] (20, 0) NULL,
[po_on_order] [decimal] (20, 0) NULL,
[tl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Style_pom_status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Active] [smallint] NULL CONSTRAINT [DF_cvo_pom_tl_status_Active] DEFAULT ((0)),
[eff_date] [datetime] NULL,
[obs_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_active_pom_tl] ON [dbo].[cvo_pom_tl_status] ([collection], [style], [Active], [eff_date], [obs_date], [Style_pom_status]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [pom_tl_idx] ON [dbo].[cvo_pom_tl_status] ([collection], [style], [color_desc], [id]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_pom_tl_status] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_pom_tl_status] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_pom_tl_status] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_pom_tl_status] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_pom_tl_status] TO [public]
GO
