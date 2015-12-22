CREATE TABLE [dbo].[tdc_adhoc_rec_serial_archive]
(
[adhoc_rec_no] [int] NOT NULL,
[tran_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serial_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no_raw] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_tran] [datetime] NOT NULL CONSTRAINT [DF__tdc_adhoc__date___35FC5B9F] DEFAULT (getdate())
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_adhoc_rec_serial_archive] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_adhoc_rec_serial_archive] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_adhoc_rec_serial_archive] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_adhoc_rec_serial_archive] TO [public]
GO
