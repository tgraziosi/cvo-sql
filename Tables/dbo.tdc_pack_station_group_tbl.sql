CREATE TABLE [dbo].[tdc_pack_station_group_tbl]
(
[group_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[max_qty] [decimal] (20, 8) NULL,
[max_no_orders] [int] NULL,
[max_no_lines] [int] NULL,
[complete_order] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_pack_station_group_tbl] ADD CONSTRAINT [PK_tdc_pack_station_group_tbl_1] PRIMARY KEY CLUSTERED  ([group_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pack_station_group_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pack_station_group_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pack_station_group_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pack_station_group_tbl] TO [public]
GO
