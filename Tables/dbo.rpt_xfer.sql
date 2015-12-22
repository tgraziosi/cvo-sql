CREATE TABLE [dbo].[rpt_xfer]
(
[xfer_no] [int] NULL,
[from_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[req_ship_date] [datetime] NULL,
[sch_ship_date] [datetime] NULL,
[date_shipped] [datetime] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_line_no] [int] NULL,
[l_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_ordered] [decimal] (20, 8) NULL,
[l_shipped] [decimal] (20, 8) NULL,
[l_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_to_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b_bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b_lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b_qty] [decimal] (20, 8) NULL,
[lf_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lt_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[s_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_xfer] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_xfer] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_xfer] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_xfer] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_xfer] TO [public]
GO
