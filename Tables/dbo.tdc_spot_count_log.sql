CREATE TABLE [dbo].[tdc_spot_count_log]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_time] [datetime] NULL CONSTRAINT [DF__tdc_spot___date___6ECAC4A7] DEFAULT (getdate()),
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_spot_count_log_idx1] ON [dbo].[tdc_spot_count_log] ([location], [bin_no], [date_time], [userid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_spot_count_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_spot_count_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_spot_count_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_spot_count_log] TO [public]
GO
