CREATE TABLE [dbo].[tdc_dist_control_seq]
(
[method] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[function] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lvl] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [TDC_DIST_SEQ_INDEX] ON [dbo].[tdc_dist_control_seq] ([method], [sequence]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_dist_control_seq] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_dist_control_seq] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_dist_control_seq] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_dist_control_seq] TO [public]
GO
