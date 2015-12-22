CREATE TABLE [dbo].[tdc_spot_count]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[spot_count_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[current_times_empty] [int] NULL CONSTRAINT [DF__tdc_spot___curre__6CE27C35] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_spot_count] ADD CONSTRAINT [empty_bin_PK] PRIMARY KEY CLUSTERED  ([location], [bin_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_spot_count] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_spot_count] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_spot_count] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_spot_count] TO [public]
GO
