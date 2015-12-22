SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_slot_commit]
	@priority		int = -1,
	@userid 		varchar(50),
	@err_msg		varchar(255) OUTPUT
AS

DECLARE	@from_bin 	varchar(12),
	@to_bin 	varchar(12),
	@location 	varchar(10),
	@qty 		decimal(20,8),
	@qty_in_bin	decimal(20,8),
	@qty_going_to_bin	decimal(20,8),
	@qty_allowed	decimal(20,8),
	@lot_ser 	varchar(25),
	@tran_id	int,
	@seq_no 	int,
	@part_no 	varchar(30),
	@q_seq_no 	int

	SELECT @tran_id = 1

	IF @priority = -1
	BEGIN
		SELECT @priority = ISNULL((SELECT  value_str FROM tdc_config (NOLOCK)  
			WHERE [function] = 'MGT_Pick_Q_Priority' and active = 'Y'), 0)
	END

	IF @priority = 0
	BEGIN
		SELECT @err_msg = 'Error Invalid Priority .'
		RETURN -1
	END

DECLARE move_cursor CURSOR FOR
	SELECT location, part_no, lot_ser, from_bin, to_bin, qty, seq_no
	  FROM #tdc_slot_bin_moves  (NOLOCK) 
	WHERE tran_id = @tran_id
	  AND sel_flg <> 0
	  AND msg IS NULL
	ORDER BY seq_no
OPEN move_cursor
FETCH NEXT FROM move_cursor INTO @location, @part_no, @lot_ser, @from_bin, @to_bin, @qty, @seq_no
WHILE (@@FETCH_STATUS = 0)
BEGIN
	--Make sure we still have the inventory to move
	IF EXISTS(SELECT * FROM lot_bin_stock (NOLOCK) WHERE location = @location AND part_no = @part_no AND lot_ser = @lot_ser AND bin_no = @from_bin AND qty >= @qty)
	BEGIN
		SELECT @qty_in_bin = ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE location = @location AND part_no = @part_no AND bin_no = @to_bin

		SELECT @qty_going_to_bin = ISNULL(SUM(qty_to_process), 0) FROM tdc_pick_queue (NOLOCK) WHERE trans_source = 'MGT' AND trans = 'MGTB2B' AND location = @location AND part_no = @part_no AND next_op = @to_bin

		SELECT @qty_allowed = ISNULL(qty, 0) FROM tdc_bin_part_qty (NOLOCK) WHERE location = @location AND part_no = @part_no AND bin_no = @to_bin

		--Make sure we are not exceeding the allowed bin qty
		IF (@qty_in_bin + @qty + @qty_going_to_bin) <= @qty_allowed
		BEGIN
			EXEC @q_seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority 	
		
			INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,
				location, trans_type_no, trans_type_ext, line_no, part_no, lot,qty_to_process, 
				qty_processed, qty_short, next_op, bin_no, date_time, tx_control, tx_lock, [user_id])
			VALUES ('MGT', 'MGTB2B', @priority, @q_seq_no, @location, 0, 0, 0, 
				@part_no, @lot_ser, @qty, 0, 0, @to_bin, @from_bin, GETDATE(), 'M', 'R', @userid) 
		END
	END
	FETCH NEXT FROM move_cursor INTO @location, @part_no, @lot_ser, @from_bin, @to_bin, @qty, @seq_no
END
CLOSE move_cursor
DEALLOCATE move_cursor
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_slot_commit] TO [public]
GO
