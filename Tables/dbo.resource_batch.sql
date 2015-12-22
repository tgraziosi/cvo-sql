CREATE TABLE [dbo].[resource_batch]
(
[timestamp] [timestamp] NOT NULL,
[batch_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_date] [datetime] NOT NULL,
[last_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buyer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[combine_days] [int] NOT NULL CONSTRAINT [DF__resource___combi__403167FD] DEFAULT ((1)),
[time_fence_end_date] [datetime] NOT NULL,
[explode_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___explo__41258C36] DEFAULT ('N'),
[demand_neg_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__4219B06F] DEFAULT ('N'),
[demand_min_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__430DD4A8] DEFAULT ('N'),
[demand_so_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__4401F8E1] DEFAULT ('N'),
[demand_fcast_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__44F61D1A] DEFAULT ('N'),
[demand_xfer_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__45EA4153] DEFAULT ('N'),
[demand_wo_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__46DE658C] DEFAULT ('N'),
[demand_rtv_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__47D289C5] DEFAULT ('N'),
[demand_stock_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__48C6ADFE] DEFAULT ('N'),
[demand_so_hold_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___deman__49BAD237] DEFAULT ('N'),
[supply_po_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___suppl__4AAEF670] DEFAULT ('N'),
[supply_qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___suppl__4BA31AA9] DEFAULT ('N'),
[supply_xfer_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___suppl__4C973EE2] DEFAULT ('N'),
[supply_return_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___suppl__4D8B631B] DEFAULT ('N'),
[supply_wo_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___suppl__4E7F8754] DEFAULT ('N'),
[supply_wo_qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___suppl__4F73AB8D] DEFAULT ('N'),
[supply_stock_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___suppl__5067CFC6] DEFAULT ('N'),
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[demand_so_internal_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__resource___deman__515BF3FF] DEFAULT ('Y'),
[demand_so_external_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__resource___deman__52501838] DEFAULT ('Y'),
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_fcast_flag] CHECK (([demand_fcast_flag]='N' OR [demand_fcast_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_min_flag] CHECK (([demand_min_flag]='X' OR [demand_min_flag]='N' OR [demand_min_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_neg_flag] CHECK (([demand_neg_flag]='N' OR [demand_neg_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_rtv_flag] CHECK (([demand_rtv_flag]='N' OR [demand_rtv_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_so_flag] CHECK (([demand_so_flag]='N' OR [demand_so_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_so_hold_flag] CHECK (([demand_so_hold_flag]='N' OR [demand_so_hold_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_stock_flag] CHECK (([demand_stock_flag]='N' OR [demand_stock_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_wo_flag] CHECK (([demand_wo_flag]='N' OR [demand_wo_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_demand_xfer_flag] CHECK (([demand_xfer_flag]='N' OR [demand_xfer_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_explode_flag] CHECK (([explode_flag]='N' OR [explode_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_supply_po_flag] CHECK (([supply_po_flag]='N' OR [supply_po_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_supply_qc_flag] CHECK (([supply_qc_flag]='N' OR [supply_qc_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_supply_return_flag] CHECK (([supply_return_flag]='N' OR [supply_return_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_supply_stock_flag] CHECK (([supply_stock_flag]='N' OR [supply_stock_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_supply_wo_flag] CHECK (([supply_wo_flag]='N' OR [supply_wo_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_supply_wo_qc_flag] CHECK (([supply_wo_qc_flag]='N' OR [supply_wo_qc_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [CK_resource_batch_supply_xfer_flag] CHECK (([supply_xfer_flag]='N' OR [supply_xfer_flag]='Y'))
GO
CREATE UNIQUE CLUSTERED INDEX [PK_resource_batch] ON [dbo].[resource_batch] ([batch_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [FK_resource_batch_buyers_buyer] FOREIGN KEY ([buyer]) REFERENCES [dbo].[buyers] ([kys])
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [FK_resource_batch_category_category] FOREIGN KEY ([category]) REFERENCES [dbo].[category] ([kys])
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [FK_resource_batch_locations_location] FOREIGN KEY ([location]) REFERENCES [dbo].[locations_all] ([location])
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [FK_resource_batch_inv_master_part_no] FOREIGN KEY ([part_no]) REFERENCES [dbo].[inv_master] ([part_no])
GO
ALTER TABLE [dbo].[resource_batch] ADD CONSTRAINT [FK_resource_batch_part_type_part_type] FOREIGN KEY ([part_type]) REFERENCES [dbo].[part_type] ([kys])
GO
GRANT REFERENCES ON  [dbo].[resource_batch] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_batch] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_batch] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_batch] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_batch] TO [public]
GO
