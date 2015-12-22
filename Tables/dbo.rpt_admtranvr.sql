CREATE TABLE [dbo].[rpt_admtranvr]
(
[xfer_no] [int] NOT NULL,
[from_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[qty_received] [decimal] (13, 0) NULL,
[amt_variance] [decimal] (13, 0) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_admtranvr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_admtranvr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_admtranvr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_admtranvr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_admtranvr] TO [public]
GO
