CREATE TABLE [dbo].[resource_demand_group]
(
[timestamp] [timestamp] NOT NULL,
[batch_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[demand_date] [datetime] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buy_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___buy_f__58FD15C7] DEFAULT ('N'),
[uom] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_cost] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__resource___unit___59F13A00] DEFAULT ((0)),
[distinct_order_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___disti__5AE55E39] DEFAULT ('N'),
[blanket_order_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___blank__5BD98272] DEFAULT ('N'),
[blanket_po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[xfer_order_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__resource___xfer___5CCDA6AB] DEFAULT ('N'),
[location_from] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[internal_po_ind] [int] NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[resource_demand_group_del] ON [dbo].[resource_demand_group] FOR DELETE  AS 
BEGIN

--*****************************************************************************
--* After an order (purchase or transfer) has been created for a summary demand
--* row, the row is deleted from the resource_demand_group table.  This trigger
--* deletes the corresponding detail rows from resource_demand that reference
--* the same group number.
--*****************************************************************************

DELETE resource_demand
FROM   deleted
WHERE  resource_demand.batch_id = deleted.batch_id and
	resource_demand.group_no = deleted.group_no

END

GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [CK_resource_demand_group_blanket_order_flag] CHECK (([blanket_order_flag]='N' OR [blanket_order_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [CK_resource_demand_group_buy_flag] CHECK (([buy_flag]='N' OR [buy_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [CK_resource_demand_group_distinct_order_flag] CHECK (([distinct_order_flag]='N' OR [distinct_order_flag]='Y'))
GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [CK_resource_demand_group_xfer_order_flag] CHECK (([xfer_order_flag]='N' OR [xfer_order_flag]='Y'))
GO
CREATE NONCLUSTERED INDEX [resdemgrp2] ON [dbo].[resource_demand_group] ([batch_id], [buy_flag], [blanket_order_flag], [location], [xfer_order_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [resdemgrp1] ON [dbo].[resource_demand_group] ([batch_id], [buy_flag], [qty]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [resdemgrp3] ON [dbo].[resource_demand_group] ([batch_id], [group_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [FK_resource_demand_group_resource_batch_batch_id] FOREIGN KEY ([batch_id]) REFERENCES [dbo].[resource_batch] ([batch_id])
GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [FK_resource_demand_group_purchase_blanket_po_no] FOREIGN KEY ([blanket_po_no]) REFERENCES [dbo].[purchase_all] ([po_no])
GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [FK_resource_demand_group_locations_location] FOREIGN KEY ([location]) REFERENCES [dbo].[locations_all] ([location])
GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [FK_resource_demand_group_locations_location_from] FOREIGN KEY ([location_from]) REFERENCES [dbo].[locations_all] ([location])
GO
ALTER TABLE [dbo].[resource_demand_group] ADD CONSTRAINT [FK_resource_demand_group_uom_list_uom] FOREIGN KEY ([uom]) REFERENCES [dbo].[uom_list] ([uom])
GO
GRANT REFERENCES ON  [dbo].[resource_demand_group] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_demand_group] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_demand_group] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_demand_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_demand_group] TO [public]
GO
