CREATE TABLE [dbo].[atmtcdet]
(
[timestamp] [timestamp] NOT NULL,
[invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [float] NOT NULL,
[unit_price] [float] NOT NULL,
[amt_tax] [float] NULL,
[amt_discount] [float] NULL,
[amt_freight] [float] NULL,
[amt_misc] [float] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [atmtcdet_ind_0] ON [dbo].[atmtcdet] ([invoice_no], [vendor_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[atmtcdet] TO [public]
GO
GRANT SELECT ON  [dbo].[atmtcdet] TO [public]
GO
GRANT INSERT ON  [dbo].[atmtcdet] TO [public]
GO
GRANT DELETE ON  [dbo].[atmtcdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[atmtcdet] TO [public]
GO
