SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_slot_empty_bin]
		@template_id 	int,
		@bin_to_empty 	varchar(12),
		@part_no 	varchar(30) = NULL,
		@err_msg	varchar(255) OUTPUT
AS
DECLARE	@bin_no 	varchar(12),
	@location 	varchar(10),
	@qty 		decimal(20,8),
	@lot_ser 	varchar(25),
	@tran_id 	int,
	@seq_no 	int

DECLARE	@bin_qty 		decimal(20,8),
	@space_qty 		decimal(20,8),
	@qty_in_bin		decimal(20,8),
	@qty_queued		decimal(20,8),
	@qty_moving_to_bin	decimal(20,8)

IF NOT EXISTS (SELECT * 
		 FROM tdc_graphical_bin_store (NOLOCK) 
		WHERE template_id = @template_id 
		  AND bin_no = @bin_to_empty)
BEGIN
	SELECT @err_msg = 'Target bin is not in the template'
	RETURN -1
END

TRUNCATE TABLE #tdc_slot_bin_moves

SELECT @location = location 
  FROM tdc_graphical_bin_template (NOLOCK) 
WHERE template_id = @template_id

IF @part_no = ''
  SELECT @part_no = NULL

SELECT	@seq_no=1,
	@tran_id = ISNULL(MAX(tran_id), 0) + 1 FROM #tdc_slot_bin_moves

IF (@part_no IS NULL)
BEGIN
	DECLARE inv_cursor CURSOR FOR
		SELECT part_no, lot_ser, --qty 
		qty - (	SELECT ISNULL(SUM(qty_to_process), 0) --subtracting allocated qty
			FROM tdc_pick_queue  (NOLOCK) 
			WHERE location = @location
			  AND part_no = lot_bin_stock.part_no
			  AND lot_ser = lot_bin_stock.lot_ser
			  AND bin_no = @bin_to_empty
		) AS avail_qty	
		FROM lot_bin_stock  (NOLOCK) 
		WHERE location = @location 
		  AND bin_no = @bin_to_empty
END
ELSE 
BEGIN
	DECLARE inv_cursor CURSOR FOR
		SELECT part_no, lot_ser, --qty 
		qty - (	SELECT ISNULL(SUM(qty_to_process), 0) --subtracting allocated qty
			FROM tdc_pick_queue  (NOLOCK) 
			WHERE location = @location
			  AND part_no = lot_bin_stock.part_no
			  AND lot_ser = lot_bin_stock.lot_ser
			  AND bin_no = @bin_to_empty
		) AS avail_qty	
		FROM lot_bin_stock (NOLOCK) 
		WHERE location = @location 
		  AND part_no = @part_no
		  AND bin_no = @bin_to_empty
END
OPEN inv_cursor
FETCH NEXT FROM inv_cursor INTO @part_no, @lot_ser, @qty
WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE bin_cursor CURSOR FOR
		SELECT bin_no, qty
		  FROM tdc_bin_part_qty (NOLOCK) 
		WHERE location = @location
		  AND part_no = @part_no
		  AND bin_no <> @bin_to_empty
		  AND EXISTS (SELECT *	--bin must be in template
				FROM tdc_graphical_bin_store (NOLOCK) 
				WHERE template_id = @template_id
				  AND tdc_graphical_bin_store.bin_no = tdc_bin_part_qty.bin_no)
		  AND NOT EXISTS (SELECT *	--can't be a mixed bin
				FROM lot_bin_stock (NOLOCK) 
				WHERE lot_bin_stock.location = @location
				  AND lot_bin_stock.part_no <> @part_no				
				  AND lot_bin_stock.bin_no = tdc_bin_part_qty.bin_no)
		  AND NOT EXISTS (SELECT * 	--can't already have another part queued to go there.
				FROM tdc_pick_queue (NOLOCK) 
				WHERE location = @location
				  AND part_no <> @part_no
				  AND trans = 'MGTB2B'
				  AND next_op = tdc_bin_part_qty.bin_no)
		  AND NOT EXISTS (SELECT *	--can't already have another part scheduled to go there.
				FROM #tdc_slot_bin_moves (NOLOCK) 
				WHERE tran_id = @tran_id
				  AND to_bin = tdc_bin_part_qty.bin_no
				  AND part_no <> @part_no)
		ORDER BY tdc_bin_part_qty.seq_no
	OPEN bin_cursor
	FETCH NEXT FROM bin_cursor INTO @bin_no, @bin_qty
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--calculate space qty
		SELECT @qty_in_bin = ISNULL(SUM(qty), 0)		--this is the quantity already in the bin
		  FROM lot_bin_stock  (NOLOCK) 
		WHERE location = @location
		  AND part_no = @part_no
		  AND bin_no = @bin_no

		SELECT @qty_queued = ISNULL(SUM(qty_to_process), 0)	--this is the quantity queued to be put in the bin
		  FROM tdc_pick_queue (NOLOCK) 
		WHERE location = @location
		  AND part_no = @part_no
		  AND trans = 'MGTB2B'
		  AND next_op = @bin_no

		SELECT @qty_moving_to_bin = ISNULL(SUM(qty), 0)		--this is the quantity that we've already decided
		  FROM #tdc_slot_bin_moves (NOLOCK) 			-- to put in the bin
		WHERE tran_id = @tran_id
		  AND to_bin = @bin_no
		  AND part_no = @part_no

		SELECT @space_qty = @bin_qty - @qty_in_bin + @qty_queued + @qty_moving_to_bin

		--compare quantities
		IF @space_qty > @qty
		BEGIN
			INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
						VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @bin_to_empty, @bin_no, @qty, NULL)
			SELECT @qty = 0, @seq_no = @seq_no + 1
			BREAK
		END
		ELSE IF @space_qty > 0
		BEGIN
			INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
						VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @bin_to_empty, @bin_no, @space_qty, NULL)
			SELECT @qty = @qty - @space_qty,  @seq_no = @seq_no + 1
		END

		FETCH NEXT FROM bin_cursor INTO @bin_no, @bin_qty
	END
	CLOSE bin_cursor
	DEALLOCATE bin_cursor

	IF (@qty > 0)
	BEGIN
		INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
					VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @bin_to_empty, NULL, @qty, 'Cannot Move.  No valid destination.')
		SELECT @seq_no = @seq_no + 1
	END

	FETCH NEXT FROM inv_cursor INTO @part_no, @lot_ser, @qty
END
CLOSE inv_cursor
DEALLOCATE inv_cursor

UPDATE #tdc_slot_bin_moves
	SET sel_flg = -1
WHERE msg IS NULL

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_slot_empty_bin] TO [public]
GO
