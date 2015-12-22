CREATE TABLE [dbo].[tdc_carton_station]
(
[station_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[carton_no] [int] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_carton_station] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_carton_station] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_carton_station] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_carton_station] TO [public]
GO
