CREATE TABLE [dbo].[tdc_tote_bin_tbl]
(
[bin_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[orig_bin] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [int] NOT NULL,
[tran_date] [datetime] NOT NULL,
[who] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_totebin_idx1] ON [dbo].[tdc_tote_bin_tbl] ([bin_no], [part_no], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_totebin_idx2] ON [dbo].[tdc_tote_bin_tbl] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_tote_bin_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_tote_bin_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_tote_bin_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_tote_bin_tbl] TO [public]
GO
