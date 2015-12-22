CREATE TABLE [dbo].[tdc_rfid_cfg]
(
[device_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[flag] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[value_str] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_rfid_cfg_IDX1] ON [dbo].[tdc_rfid_cfg] ([device_name], [flag]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_rfid_cfg] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_rfid_cfg] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_rfid_cfg] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_rfid_cfg] TO [public]
GO
