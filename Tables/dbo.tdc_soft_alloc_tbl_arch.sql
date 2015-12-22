CREATE TABLE [dbo].[tdc_soft_alloc_tbl_arch]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[wo_seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[target_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dest_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[insert_time] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_soft_alloc_tbl_arch] ADD CONSTRAINT [PK_tdc_soft_alloc_tbl_arch] PRIMARY KEY NONCLUSTERED  ([insert_time], [order_no], [order_ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_soft_alloc_tbl_arch] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_soft_alloc_tbl_arch] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_soft_alloc_tbl_arch] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_soft_alloc_tbl_arch] TO [public]
GO
