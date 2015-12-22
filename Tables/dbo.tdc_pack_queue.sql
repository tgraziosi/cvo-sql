CREATE TABLE [dbo].[tdc_pack_queue]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[picked] [decimal] (20, 8) NOT NULL,
[packed] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__tdc_pack___packe__19EA2CD6] DEFAULT ((0)),
[group_id] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[station_id] [int] NOT NULL,
[last_modified_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_pack___last___1ADE510F] DEFAULT (getdate()),
[last_modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_pack_queue_idx01] ON [dbo].[tdc_pack_queue] ([order_no], [order_ext], [line_no], [part_no], [group_id], [station_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pack_queue] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pack_queue] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pack_queue] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pack_queue] TO [public]
GO
