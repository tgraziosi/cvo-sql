CREATE TABLE [dbo].[rpt_phytag]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phy_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[orig_qty] [decimal] (20, 8) NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phy_batch] [int] NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_expires] [datetime] NULL,
[b_qty] [decimal] (20, 8) NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serial_flag] [int] NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[h_dec_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[h_thou_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blind_ind] [int] NULL,
[qty_precision] [int] NULL,
[orig_qty_precision] [int] NULL,
[b_qty_precision] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_phytag] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_phytag] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_phytag] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_phytag] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_phytag] TO [public]
GO
