CREATE TABLE [dbo].[tdc_serial_no_pack]
(
[carton_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no_raw] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_serial_no_pack] ON [dbo].[tdc_serial_no_pack] ([carton_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_serial_no_pack] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_serial_no_pack] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_serial_no_pack] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_serial_no_pack] TO [public]
GO
