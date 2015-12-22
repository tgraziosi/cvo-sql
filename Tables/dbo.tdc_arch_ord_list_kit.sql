CREATE TABLE [dbo].[tdc_arch_ord_list_kit]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[picked] [decimal] (20, 8) NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[kit_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_kit_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_per_kit] [decimal] (20, 8) NOT NULL,
[kit_picked] [decimal] (20, 8) NOT NULL,
[date_archived] [datetime] NULL,
[who_archived] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_arch_ord_list_kit] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_arch_ord_list_kit] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_arch_ord_list_kit] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_arch_ord_list_kit] TO [public]
GO
