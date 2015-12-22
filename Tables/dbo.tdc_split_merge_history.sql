CREATE TABLE [dbo].[tdc_split_merge_history]
(
[from_carton] [int] NOT NULL,
[to_carton] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serial_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tx_date] [datetime] NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orgin_pre_pack_qty] [decimal] (24, 8) NOT NULL,
[orgin_packed_qty] [decimal] (24, 8) NOT NULL,
[moved_qty] [decimal] (24, 8) NOT NULL,
[from_carton_printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_split__from___6911EB51] DEFAULT ('N'),
[to_carton_printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_split__to_ca__6A060F8A] DEFAULT ('N')
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_split_merge_history] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_split_merge_history] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_split_merge_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_split_merge_history] TO [public]
GO
