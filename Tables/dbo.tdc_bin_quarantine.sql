CREATE TABLE [dbo].[tdc_bin_quarantine]
(
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[original_usage_type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quarantined_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quarantined_when] [datetime] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_quarantine] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_quarantine] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_quarantine] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_quarantine] TO [public]
GO
