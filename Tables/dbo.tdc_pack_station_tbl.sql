CREATE TABLE [dbo].[tdc_pack_station_tbl]
(
[station_id] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[station_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[auto_qty] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[manifest_enabled] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[auto_manifest] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[manifest_host_ip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[manifest_host_port] [int] NULL,
[manifest_timeout] [int] NULL,
[master_pack] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[manifest_point] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fedex_comm_port] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fedex_comm_speed] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fedex_printer_type] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fedex_media_type] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scale_enabled] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[scale_inq_msg] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scale_comm_port] [int] NULL,
[scale_baud] [int] NULL,
[scale_parity] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scale_data_bits] [int] NULL,
[scale_stop_bits] [int] NULL,
[scale_timeout] [int] NULL,
[scale_weight_source] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[scale_weight_capture_pt] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_pack_station_tbl] ADD CONSTRAINT [PK_tdc_pack_station_tbl_1] PRIMARY KEY CLUSTERED  ([station_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pack_station_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pack_station_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pack_station_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pack_station_tbl] TO [public]
GO
