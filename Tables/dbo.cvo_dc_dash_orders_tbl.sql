CREATE TABLE [dbo].[cvo_dc_dash_orders_tbl]
(
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_DESC] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[ordertype] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FramesOrdered] [decimal] (38, 8) NULL,
[date_sch_ship] [datetime] NULL,
[Cust_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[timeslot] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asofdate] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_dash_ord] ON [dbo].[cvo_dc_dash_orders_tbl] ([ordertype], [status_DESC]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_dc_dash_orders_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_dc_dash_orders_tbl] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_dc_dash_orders_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_dc_dash_orders_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_dc_dash_orders_tbl] TO [public]
GO
