SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_adh_update_serial_track_sp]
@tran_id	INT,
@part_no	VARCHAR(30),
@location	VARCHAR(15), 
@lot		VARCHAR(15), 
@bin		VARCHAR(30), 
@userid		VARCHAR(50),
@insertmode	INT --1 = INSERT, 0 = DELETE
AS
DECLARE 
@mask   	VARCHAR(50),
@serial_no	VARCHAR(30), 
@MaskedSerial	VARCHAR(50),
@errmsg		VARCHAR(255),
@lRet		INT

DECLARE serial_update_cur 
CURSOR FOR
SELECT serial_no FROM #temp_serial_numbers

OPEN serial_update_cur

FETCH NEXT FROM serial_update_cur INTO @serial_no

WHILE @@FETCH_STATUS = 0
BEGIN

	IF @insertmode = 1 --INSERTMODE
	BEGIN
		SELECT @mask = mask_code FROM tdc_inv_master(NOLOCK)
			WHERE part_no = @part_no
	
	
		EXEC @lRet = tdc_format_serial_mask_sp @part_no, @serial_no, @MaskedSerial, @errmsg
		IF @lRet < 0 
			RAISERROR (@errmsg, 16, 1)
	
		IF EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)   
			WHERE part_no   =  @part_no
			AND lot_ser   =  @lot
			AND location = @location
			AND serial_no = @serial_no 
			AND arbc_no = @bin
			AND last_tx_control_no = @tran_id	
			AND io_count % 2 = 1 )
		BEGIN
			UPDATE tdc_serial_no_track
			SET io_count = io_count + 1,
			last_control_type = 'A',  
			last_trans = 'ADHOCREC',
			last_tx_control_no = @tran_id  
			WHERE part_no   =  @part_no
			AND lot_ser   =  @lot
			AND location = @location
			AND serial_no = @serial_no 
			AND arbc_no = @bin
			AND last_tx_control_no = @tran_id	
			AND io_count % 2 = 1 
		
		END
		ELSE   
		BEGIN
	
			--Adhoc Receipts
			INSERT INTO tdc_serial_no_track
				(location,transfer_location, part_no, lot_ser, mask_code, serial_no, serial_no_raw,
				 IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, 
				 last_trans, last_tx_control_no, date_time, [user_id], arbc_no)
			VALUES ( @location, @location, @part_no, @lot, @mask, @serial_no, @serial_no,
				 1, 'A', 'ADHOCREC', @tran_id, 'A', 
				 'ADHOCREC', @tran_id, GETDATE(), @userid, @bin)	
		
		END
	END
	ELSE --DELETE MODE
	BEGIN
		UPDATE tdc_serial_no_track  
		SET io_count = io_count - 1
			WHERE part_no   =  @part_no
			AND lot_ser   =  @lot
			AND location = @location
			AND serial_no = @serial_no 
			AND arbc_no = @bin
			AND last_tx_control_no = @tran_id				

		DELETE FROM tdc_serial_no_track  
			WHERE part_no   =  @part_no
			AND lot_ser   =  @lot
			AND location = @location
			AND serial_no = @serial_no 
			AND arbc_no = @bin
			AND last_tx_control_no = @tran_id	
			AND io_count = 0
	END
	FETCH NEXT FROM serial_update_cur INTO @serial_no
END

CLOSE serial_update_cur
DEALLOCATE serial_update_cur
RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_adh_update_serial_track_sp] TO [public]
GO
