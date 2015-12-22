SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_slot_org_inv]
		@template_id 	int,
		@part_no 	varchar(30) = NULL,
		@err_msg	varchar(255) OUTPUT

AS
--ALL PARTS FOR A GIVEN TEMPLATE
DECLARE	@from_bin	varchar(12),
	@to_bin		varchar(12),
	@seq_no		int,
	@tran_id	int,
	@from_bin_seq	int,
	@to_bin_seq	int,
	@found_to_bin	smallint,
	@location	varchar(12),
	@lot_ser	varchar(30),
	@qty		decimal(20,8),
	@to_bin_qty	decimal(20,8),
	@in_stock_qty	decimal(20,8),
	@queue_qty	decimal(20,8),
	@space_qty	decimal(20,8),
	@slot_bin_moving_to_qty		decimal(20,8),
	@slot_bin_moving_from_qty	decimal(20,8)

TRUNCATE TABLE #tdc_slot_bin_moves

IF NOT EXISTS(SELECT * FROM tdc_graphical_bin_template (NOLOCK) WHERE template_id = @template_id)
BEGIN
	SELECT @err_msg = 'Specified template does not exist.'
	RETURN -1
END

IF @part_no = ''
  SELECT @part_no = NULL

SELECT @location = location 
	FROM tdc_graphical_bin_template (NOLOCK) 
	WHERE template_id = @template_id

SELECT	@seq_no=1,
	@tran_id = ISNULL(MAX(tran_id), 0) + 1 FROM #tdc_slot_bin_moves (NOLOCK)

IF (@part_no IS NULL)	--Get all the parts that are configured for this template
BEGIN
	DECLARE bin_parts CURSOR FOR
	SELECT DISTINCT lbs.part_no
	FROM 	lot_bin_stock lbs (NOLOCK) , 
		tdc_bin_part_qty tbpq (NOLOCK) , 
		tdc_graphical_bin_store tgbs (NOLOCK) 
	WHERE lbs.location  = @location
	  AND tbpq.location = lbs.location
	  AND tbpq.part_no = lbs.part_no
	  AND tgbs.template_id = @template_id
	  AND tgbs.bin_no = lbs.bin_no
-- 	SELECT DISTINCT lbs.part_no
-- 	FROM 	lot_bin_stock lbs (NOLOCK) , 
-- 		tdc_bin_part_qty tbpq (NOLOCK) , 
-- 		tdc_graphical_bin_store tgbs (NOLOCK) 
-- 	WHERE lbs.location  = @location
-- 	  AND tbpq.location = lbs.location
-- 	  AND lbs.bin_no = tbpq.bin_no
-- 	  AND tgbs.template_id = @template_id
-- 	  AND tgbs.bin_no = lbs.bin_no
END
ELSE
BEGIN
	DECLARE bin_parts CURSOR FOR
		SELECT @part_no
END
OPEN bin_parts
FETCH NEXT FROM bin_parts INTO @part_no
WHILE @@FETCH_STATUS = 0
BEGIN

--GET ALL OF THE BINS TO MOVE "FROM"
DECLARE from_bin_cursor CURSOR FOR
	SELECT 	a.bin_no, 
		a.lot_ser, 
		a.qty, 
		CASE WHEN EXISTS(SELECT * FROM tdc_bin_part_qty (NOLOCK) WHERE bin_no = a.bin_no AND location = a.location AND part_no = a.part_no) THEN (SELECT seq_no FROM tdc_bin_part_qty (NOLOCK) WHERE bin_no = a.bin_no AND location = a.location AND part_no = a.part_no) ELSE 99999999 END
	FROM 	lot_bin_stock		a (NOLOCK), 
		tdc_graphical_bin_store b (NOLOCK)
	WHERE a.bin_no 	    = b.bin_no
	  AND a.location    = @location
	  AND a.part_no     = @part_no
	  AND b.template_id = @template_id
	ORDER BY 4 DESC
OPEN from_bin_cursor
FETCH NEXT FROM from_bin_cursor INTO @from_bin, @lot_ser, @qty, @from_bin_seq
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @found_to_bin = 0

	--SELECT 'From bins for part: ' + @part_no, @from_bin [bin], @lot_ser[lot_ser], @qty[qty], @from_bin_seq [bin_seq]

	IF NOT EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) 
		WHERE trans = 'MGTB2B' 
		  AND location = @location 
		  AND bin_no = @from_bin 
		  AND lot = @lot_ser
		  AND qty_to_process = @qty)
	BEGIN
		--GET ALL OF THE BINS TO MOVE TO
		DECLARE to_bin_cursor CURSOR FOR
			SELECT tgbs.bin_no, tbpq.seq_no, tbpq.qty
			  FROM 	tdc_graphical_bin_store tgbs (NOLOCK),
				tdc_bin_part_qty tbpq (NOLOCK)
			WHERE tgbs.template_id = @template_id
			  AND tgbs.bin_no = tbpq.bin_no
			  AND tbpq.location = @location
			  AND tbpq.part_no = @part_no
			  AND tgbs.bin_no <> @from_bin
			  AND tbpq.seq_no < @from_bin_seq
			ORDER BY tbpq.seq_no
		OPEN to_bin_cursor
		FETCH NEXT FROM to_bin_cursor INTO @to_bin, @to_bin_seq, @to_bin_qty
		WHILE @@FETCH_STATUS = 0
		BEGIN
			--Make sure the "to bin" is not a mixed bin, we won't move anything into a mixed bin
			IF NOT EXISTS(SELECT * FROM lot_bin_stock (NOLOCK) WHERE location = @location AND bin_no = @to_bin AND part_no <> @part_no)
			BEGIN
			  --Make sure that pending moves will not make this "to bin" a mixed bin
			  IF NOT EXISTS(SELECT * FROM #tdc_slot_bin_moves (NOLOCK) WHERE to_bin = @to_bin AND part_no <> @part_no)
			  BEGIN
			    --Make sure that no different parts are coming into this "to bin" from the pick queue
			    IF NOT EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans = 'MGTB2B' AND location = @location AND next_op = @to_bin AND part_no <> @part_no)
			    BEGIN
				--See how much room we have left in this bin
				--determine how many more parts we can fit in the bin	
				SELECT @in_stock_qty = (SELECT ISNULL(SUM(qty), 0)
					FROM lot_bin_stock (NOLOCK) 
					WHERE location = @location
					  AND part_no = @part_no
					  AND bin_no = @to_bin)
				
				SELECT @queue_qty = (SELECT ISNULL(SUM(qty_to_process), 0)
					FROM tdc_pick_queue (NOLOCK) 
					WHERE trans = 'MGTB2B'
					  AND location = @location
					  AND next_op = @to_bin
					  AND part_no = @part_no)
	
				SELECT @slot_bin_moving_to_qty = (SELECT ISNULL(SUM(qty), 0)
					FROM #tdc_slot_bin_moves (NOLOCK) 
					WHERE tran_id = @tran_id
					  AND part_no = @part_no
					  AND to_bin = @to_bin)
				
				SELECT @slot_bin_moving_from_qty = (SELECT ISNULL(SUM(qty), 0)
					FROM #tdc_slot_bin_moves (NOLOCK) 
					WHERE tran_id = @tran_id
					  AND part_no = @part_no
					  AND from_bin = @to_bin)
				
				SELECT @space_qty = @to_bin_qty - (@in_stock_qty + @queue_qty + @slot_bin_moving_to_qty) - @slot_bin_moving_from_qty
		
				--SELECT '  Valid part: ' + @part_no , @to_bin[to_bin], @to_bin_seq [to_bin_seq], @to_bin_qty [to_bin_qty]
				----Insert into #tdc_slot_bin_moves
				IF @space_qty >= @qty
				BEGIN
					INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
								VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @from_bin, @to_bin, @qty, NULL)
					SELECT @qty = 0, @seq_no = @seq_no + 1, @found_to_bin = 1
					BREAK
				END
				ELSE IF @space_qty > 0
				BEGIN
					INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
								VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @from_bin, @to_bin, @space_qty, NULL)
					SELECT @qty = @qty - @space_qty,  @seq_no = @seq_no + 1, @found_to_bin = 1
				END
				ELSE
				BEGIN
					SELECT @found_to_bin = 0
				END
			    END
			  END
			END
		  FETCH NEXT FROM to_bin_cursor INTO @to_bin, @to_bin_seq, @to_bin_qty
		END
		CLOSE to_bin_cursor
		DEALLOCATE to_bin_cursor
	END

	--Let's make sure that we are not already in the most optimized location for our inventory, before we say we can't move it.
	IF @from_bin_seq = (SELECT MIN(seq_no) FROM tdc_bin_part_qty WHERE location = @location AND part_no = @part_no AND bin_no = @from_bin)
		SELECT @found_to_bin = 1

	--WE were not able to move the inventory
	IF @found_to_bin = 0
	BEGIN
		INSERT INTO #tdc_slot_bin_moves ( tran_id,  seq_no,  location,  part_no,  lot_ser, from_bin, to_bin,  qty,  msg)
					VALUES (@tran_id, @seq_no, @location, @part_no, @lot_ser, @from_bin, NULL, @qty, 'Cannot Move.  No valid destination.')
		SELECT @seq_no = @seq_no + 1			
	END
  FETCH NEXT FROM from_bin_cursor INTO @from_bin, @lot_ser, @qty, @from_bin_seq
END
CLOSE from_bin_cursor
DEALLOCATE from_bin_cursor

   FETCH NEXT FROM bin_parts INTO @part_no
END
CLOSE bin_parts
DEALLOCATE bin_parts

UPDATE #tdc_slot_bin_moves
	SET sel_flg = -1
WHERE msg IS NULL

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_slot_org_inv] TO [public]
GO
