CREATE TABLE [dbo].[cvo_dc_dashboard_arch_tbl]
(
[Tag] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[must_go_today] [int] NULL,
[num_orders] [int] NULL,
[asofdate] [datetime] NOT NULL,
[id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_dc_dashboard_arch_tbl] TO [public]
GO
