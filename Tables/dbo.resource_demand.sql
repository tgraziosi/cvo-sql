CREATE TABLE [dbo].[resource_demand]
(
[timestamp] [timestamp] NOT NULL,
[batch_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[demand_date] [datetime] NOT NULL,
[ilevel] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[commit_ed] [decimal] (20, 8) NULL,
[source_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pqty] [decimal] (20, 8) NOT NULL,
[p_used] [decimal] (20, 8) NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buy_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__resource___buy_f__552C84E3] DEFAULT ('N'),
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buyer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [int] NULL,
[location2] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL CONSTRAINT [DF__resource___row_i__5620A91C] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[resource_demand] ADD CONSTRAINT [CK_resource_demand_buy_flag] CHECK (([buy_flag]='N' OR [buy_flag]='Y'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [resdem1] ON [dbo].[resource_demand] ([batch_id], [ilevel], [location], [part_no], [source], [source_no], [demand_date], [status], [parent]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [resdem1a] ON [dbo].[resource_demand] ([row_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[resource_demand] ADD CONSTRAINT [FK_resource_demand_resource_batch_batch_id] FOREIGN KEY ([batch_id]) REFERENCES [dbo].[resource_batch] ([batch_id])
GO
GRANT REFERENCES ON  [dbo].[resource_demand] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_demand] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_demand] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_demand] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_demand] TO [public]
GO
