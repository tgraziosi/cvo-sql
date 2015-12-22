CREATE TABLE [dbo].[tdc_fedex_close_request]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[station_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_fedex_close_request] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_fedex_close_request] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_fedex_close_request] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_fedex_close_request] TO [public]
GO
