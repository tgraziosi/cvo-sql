CREATE TABLE [dbo].[tdc_next_sgtin_tbl]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_next_sgtin_tbl] ADD CONSTRAINT [PK__tdc_next_sgtin_t__09B3C50D] PRIMARY KEY CLUSTERED  ([part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_next_sgtin_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_next_sgtin_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_next_sgtin_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_next_sgtin_tbl] TO [public]
GO
