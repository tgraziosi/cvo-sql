CREATE TABLE [dbo].[tdc_sgtin_next_serial]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_sgtin_next_serial] ADD CONSTRAINT [PK__tdc_sgtin_next_s__5E945CDE] PRIMARY KEY CLUSTERED  ([part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_sgtin_next_serial] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_sgtin_next_serial] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_sgtin_next_serial] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_sgtin_next_serial] TO [public]
GO
