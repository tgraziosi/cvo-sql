CREATE TABLE [dbo].[tdc_rfid_station]
(
[station_id] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[device_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_rfid_station] ADD CONSTRAINT [PK__tdc_rfid_station__42EC4269] PRIMARY KEY CLUSTERED  ([station_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_rfid_station] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_rfid_station] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_rfid_station] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_rfid_station] TO [public]
GO
