CREATE TABLE [dbo].[tdc_serial_no_history]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transfer_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mask_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no_raw] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IO_count] [int] NOT NULL,
[init_control_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[init_trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[init_tx_control_no] [int] NOT NULL,
[last_control_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_tx_control_no] [int] NOT NULL,
[date_time] [datetime] NOT NULL,
[User_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ARBC_No] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_serial_no_history] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_serial_no_history] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_serial_no_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_serial_no_history] TO [public]
GO
