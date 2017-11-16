CREATE TABLE [dbo].[cvo_item_avail_POM_weekly]
(
[Brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ResType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PartType] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[in_stock] [int] NULL,
[SOF] [decimal] (38, 8) NULL,
[Allocated] [decimal] (38, 8) NULL,
[Quarantine] [decimal] (38, 8) NULL,
[Non_alloc] [decimal] (38, 8) NULL,
[Replen_Qty_Not_SA] [decimal] (38, 8) NULL,
[qty_avl] [decimal] (38, 8) NULL,
[qty_hold] [decimal] (24, 8) NULL,
[ReplenQty] [decimal] (20, 8) NULL,
[Qty_Key] [decimal] (38, 8) NOT NULL,
[tot_cost_ea] [decimal] (23, 8) NULL,
[tot_ext_cost] [decimal] (38, 6) NULL,
[po_on_order] [decimal] (20, 8) NULL,
[NextPOOnOrder] [decimal] (38, 8) NULL,
[NextPODueDate] [datetime] NULL,
[lead_time] [int] NOT NULL,
[min_order] [decimal] (20, 8) NULL,
[min_stock] [decimal] (20, 8) NULL,
[max_stock] [decimal] (20, 8) NULL,
[order_multiple] [decimal] (20, 8) NULL,
[ReleaseDate] [datetime] NULL,
[POM_date] [datetime] NULL,
[Watch] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plc_status] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Gender] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Material] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Color_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReserveQty] [decimal] (38, 8) NULL,
[QcQty] [decimal] (38, 8) NULL,
[QcQty2] [decimal] (20, 8) NULL,
[future_ord_qty] [decimal] (38, 8) NULL,
[backorder] [decimal] (38, 8) NULL,
[asofdate] [datetime] NOT NULL,
[id] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [inv_avl_pom_asofdate_idx] ON [dbo].[cvo_item_avail_POM_weekly] ([asofdate]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [pk_inv_avl_pom_idx] ON [dbo].[cvo_item_avail_POM_weekly] ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [inv_avl_pom_idx] ON [dbo].[cvo_item_avail_POM_weekly] ([part_no], [location]) ON [PRIMARY]
GO
