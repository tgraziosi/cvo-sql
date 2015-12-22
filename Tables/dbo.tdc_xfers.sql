CREATE TABLE [dbo].[tdc_xfers]
(
[xfer_no] [int] NOT NULL,
[tdc_status] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_cartons] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_xfers] ADD CONSTRAINT [pk_tdc_xfer] PRIMARY KEY NONCLUSTERED  ([xfer_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_xfers] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_xfers] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_xfers] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_xfers] TO [public]
GO
