CREATE TABLE [dbo].[tdc_rfid_device]
(
[device_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[manufacturer] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[model] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ip_address] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[device_type] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_rfid_device] ADD CONSTRAINT [PK__tdc_rfid_device__4103F9F7] PRIMARY KEY CLUSTERED  ([device_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_rfid_device] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_rfid_device] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_rfid_device] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_rfid_device] TO [public]
GO
