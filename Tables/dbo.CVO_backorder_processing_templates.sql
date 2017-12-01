CREATE TABLE [dbo].[CVO_backorder_processing_templates]
(
[template_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sch_ship_from] [datetime] NULL,
[sch_ship_to] [datetime] NULL,
[so_priority] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[no_of_orders] [int] NULL,
[po_due_from] [datetime] NULL,
[po_due_to] [datetime] NULL,
[include_cr_hold] [smallint] NOT NULL,
[include_xfer] [smallint] NOT NULL,
[min_crossdock] [int] NULL,
[entered_date] [datetime] NOT NULL,
[entered_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[changed_date] [datetime] NULL,
[changed_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rx_reserve] [int] NULL,
[rx_reserve_days] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_templates_inx01] ON [dbo].[CVO_backorder_processing_templates] ([template_code]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_templates] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_templates] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_templates] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_templates] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_templates] TO [public]
GO
