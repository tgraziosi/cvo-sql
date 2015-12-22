CREATE TABLE [dbo].[tdc_serial_no_track]
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
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_serial_no_track_tg] ON [dbo].[tdc_serial_no_track]
FOR INSERT, UPDATE
AS
	INSERT INTO tdc_serial_no_history 
		SELECT location, transfer_location, part_no, lot_ser, mask_code, 
			serial_no, serial_no_raw, IO_count, init_control_type,
			init_trans, init_tx_control_no, last_control_type, last_trans,
			last_tx_control_no, date_time, [User_Id], ARBC_No
		FROM inserted
GO
ALTER TABLE [dbo].[tdc_serial_no_track] ADD CONSTRAINT [PK_tdc_serial_no_track] PRIMARY KEY NONCLUSTERED  ([part_no], [lot_ser], [serial_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_serial_no_track_IDX3] ON [dbo].[tdc_serial_no_track] ([date_time], [location], [part_no], [lot_ser], [serial_no], [serial_no_raw], [IO_count]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_serial_no_track_IDX1] ON [dbo].[tdc_serial_no_track] ([part_no], [lot_ser], [serial_no_raw]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_serial_no_track_IDX2] ON [dbo].[tdc_serial_no_track] ([part_no], [lot_ser], [serial_no_raw], [IO_count]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_serial_no_track] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_serial_no_track] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_serial_no_track] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_serial_no_track] TO [public]
GO
