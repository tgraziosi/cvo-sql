SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_slot_gather_part_to_bin]
		@template_id 	int,
		@target_bin 	varchar(12),
		@part_no 	varchar(30),
		@err_msg	varchar(255) OUTPUT
AS

DECLARE	@bin_no varchar(12),
	@location varchar(10),
	@qty decimal(20,8),
	@max_qty decimal(20,8),
	@cur_qty decimal(20,8),
	@lot_ser varchar(25),
	@tran_id INTEGER,
	@seq_no INTEGER

IF NOT EXISTS (SELECT * FROM tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id AND bin_no = @target_bin)
BEGIN
	SELECT @err_msg = 'Target bin is not in the template'
	RETURN -1
END

TRUNCATE TABLE #tdc_slot_bin_moves

SELECT @location = location 
	FROM tdc_graphical_bin_template (NOLOCK)
	WHERE template_id = @template_id

SELECT @max_qty = -1

SELECT @max_qty = qty
	FROM tdc_bin_part_qty (NOLOCK)
	WHERE location = @location 
	AND part_no = @part_no 
	AND bin_no = @target_bin

IF (@max_qty = -1)
BEGIN
	SELECT @err_msg = 'Target bin does not have a fill quantity assigned for this part.'
	RETURN -2
END

IF EXISTS (SELECT * FROM lot_bin_stock (NOLOCK) WHERE location = @location AND bin_no = @target_bin AND part_no <> @part_no)
BEGIN
	SELECT @err_msg = 'Target bin is a mixed bin'
	RETURN -3
END

SELECT  @cur_qty = 0, 
	@seq_no=1,
	@tran_id = ISNULL(MAX(tran_id), 0) + 1 FROM #tdc_slot_bin_moves (NOLOCK) 

DECLARE b2b_cursor CURSOR FOR SELECT bin_no, lot_ser,-- qty, 
				qty - (	SELECT ISNULL(SUM(qty_to_process), 0) --subtracting allocated qty
					FROM tdc_pick_queue  (NOLOCK) 
					WHERE location = @location
					AND bin_no = lot_bin_stock.bin_no
					AND part_no = @part_no
					AND lot_ser = lot_bin_stock.lot_ser
				) AS avail_qty
			FROM lot_bin_stock (NOLOCK) 
			WHERE part_no = @part_no 
			AND location = @location
			AND bin_no in (	SELECT bin_no 
					FROM tdc_graphical_bin_store  (NOLOCK) 
					WHERE template_id = @template_id)
			AND bin_no <> @target_bin
			ORDER BY (	SELECT seq_no 
					FROM tdc_bin_part_qty  (NOLOCK) 
					WHERE tdc_bin_part_qty.location = lot_bin_stock.location
					AND tdc_bin_part_qty.bin_no = lot_bin_stock.bin_no
					AND tdc_bin_part_qty.part_no = @part_no ) DESC

OPEN b2b_cursor
FETCH NEXT FROM b2b_cursor INTO @bin_no, @lot_ser, @qty
WHILE @@FETCH_STATUS = 0
BEGIN
	IF (@cur_qty + @qty <= @max_qty)
	BEGIN
		INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
					VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @bin_no, @target_bin, @qty, NULL)
		SELECT @cur_qty = @cur_qty + @qty, @seq_no = @seq_no + 1
	END
	ELSE IF (@cur_qty >= @max_qty)
	BEGIN
		INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
					VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @bin_no, NULL, @qty, 'Cannot Move.  Target Bin is full.')
	
	END
	ELSE
	BEGIN
		INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
					VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @bin_no, @target_bin, @max_qty - @cur_qty, NULL)

		INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
					VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @bin_no, NULL, @qty - (@max_qty - @cur_qty), 'Cannot Move.  Target Bin is full.')

		SELECT @cur_qty = @max_qty
	END
	SELECT @seq_no = @seq_no + 1
	FETCH NEXT FROM b2b_cursor INTO @bin_no, @lot_ser, @qty
END

CLOSE b2b_cursor
DEALLOCATE b2b_cursor

UPDATE #tdc_slot_bin_moves
	SET sel_flg = -1
WHERE msg IS NULL

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_slot_gather_part_to_bin] TO [public]
GO
