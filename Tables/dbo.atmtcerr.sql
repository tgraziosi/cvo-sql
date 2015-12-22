CREATE TABLE [dbo].[atmtcerr]
(
[timestamp] [timestamp] NOT NULL,
[invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [float] NULL,
[unit_price] [float] NULL,
[error_flag] [int] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [atmtcerr_ind_0] ON [dbo].[atmtcerr] ([invoice_no], [vendor_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[atmtcerr] TO [public]
GO
GRANT SELECT ON  [dbo].[atmtcerr] TO [public]
GO
GRANT INSERT ON  [dbo].[atmtcerr] TO [public]
GO
GRANT DELETE ON  [dbo].[atmtcerr] TO [public]
GO
GRANT UPDATE ON  [dbo].[atmtcerr] TO [public]
GO
