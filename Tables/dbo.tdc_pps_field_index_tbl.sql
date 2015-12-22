CREATE TABLE [dbo].[tdc_pps_field_index_tbl]
(
[field_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_index] [int] NOT NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_pps_field_index_tbl] ADD CONSTRAINT [PK_field_index] PRIMARY KEY CLUSTERED  ([field_name], [order_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pps_field_index_table_idx] ON [dbo].[tdc_pps_field_index_tbl] ([field_name], [order_type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pps_field_index_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pps_field_index_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pps_field_index_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pps_field_index_tbl] TO [public]
GO
