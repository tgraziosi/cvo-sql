SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************************************/
/* This procedure is a wrapper for tdc_bin_xfer.  It handles moving allocated inventory.	*/
/*  It changes the bin in tdc_soft_alloc_tbl.  The triggers on this table are SUPPOSED to	*/
/*  update tdc_pick_queue accordingly.  However they do not in all instances.  Therefore, this	*/
/*  stored procedure attempts to turn OFF the trigger using the trg_off bit.  Then, through	*/
/*  trial and error, I found that in some instances the trigger made the updates anyway.  In	*/
/*  those instances, the updates to tdc_pick_queue have been commented out.			*/
/************************************************************************************************/
/* CSN-05/02/02											*/
/* This was causing problems, and I revamped it.  As far as I can tell, the triggers are	*/
/* working better now, so I'm not doing anything to tdc_pick_queue, other than SELECTs.		*/
/* We made the rule that you can't bin-to-bin inventory that has been allocated for a con-	*/
/* solidation set that is not ONE-TO-ONE.  You also cannot bin-to-bin inventory that already has*/
/* a pick-ticket printed for it.								*/
/************************************************************************************************/

CREATE PROC [dbo].[tdc_bintobin_xfer]
AS

	DECLARE @issid int, @err int
	DECLARE @language varchar(10), @msg varchar(255), @part varchar(30), @who varchar(50) 
	DECLARE @from_bin varchar(12), @to_bin varchar(12), @loc varchar(10)
	DECLARE @qty decimal(20,8), @lot_ser varchar(25)
 DECLARE @in_stock DECIMAL(20, 8),
	@alloc_qty DECIMAL(20, 8),
	@qty_to_move DECIMAL(20, 8),
	@subqty DECIMAL(20, 8),
	@new_seq INT,
	@tran_id INT,
	@order_no int,
	@order_ext int,
	@order_line int,
	@q_priority int

 	/* Initialize the error code to 'No errors' */
  	SELECT @err = 0

 	/* Find the first record */
  	SELECT @issid = 0
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT MIN(who_entered) FROM #adm_bin_xfer)), 'us_english')
	SELECT @q_priority = ISNULL((SELECT CAST(value_str AS INT) FROM tdc_config (NOLOCK) WHERE [function] = 'Pick_Q_Priority') , 5)
	IF @q_priority IN ('', 0)
		SELECT @q_priority = '5'
	BEGIN TRAN
  	/* Look at each record... */
  	WHILE (@issid >= 0)
    	BEGIN
      		SELECT @issid = isnull((SELECT min(row_id) FROM #adm_bin_xfer WHERE row_id > @issid and issue_no is null),-1)
      		IF @issid     = -1 BREAK

		SELECT @part = part_no, @loc = location, @from_bin = bin_from, @to_bin = bin_to, @qty = qty,
			@lot_ser = lot_ser, @who = who_entered
			FROM #adm_bin_xfer 
				WHERE row_id = @issid

                /* Make sure enough of item is in bin */
		SELECT @in_stock = isnull(qty, 0) 
			FROM lot_bin_stock (NOLOCK)
			WHERE bin_no = @from_bin 
			AND lot_ser = @lot_ser 
			AND location = @loc 
			AND part_no = @part
		IF (@in_stock < @qty)
                BEGIN
                      	-- UPDATE #adm_bin_xfer SET err_msg = 'There is not enough of item in from bin.' WHERE row_id = @issid
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -107 AND language = @language
			RAISERROR (@msg, 16, 1)
			ROLLBACK TRAN
                      	RETURN -107
                END

		--The Following was added to handle bin-to-bin moves of allocated inventory
		SELECT @alloc_qty = ISNULL(sum(qty), 0)
			FROM tdc_soft_alloc_tbl (nolock)
			WHERE location = @loc
			AND part_no = @part 
			AND lot_ser = @lot_ser 
			AND bin_no = @from_bin

		--Checking if its necessary to move Allocated inventory.
		IF @in_stock - @alloc_qty < @qty
		BEGIN
			-- Checking Config Flag
			IF (	SELECT ISNULL(active, 'N') FROM tdc_config
					WHERE [function] = 'bin_xfer_alloc') <> 'Y'
			BEGIN
	                      	-- UPDATE #adm_bin_xfer SET err_msg = 'Cannot transfer allocated inventory' WHERE row_id = @issid
				ROLLBACK TRAN
				SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -108 AND language = @language
				RAISERROR (@msg, 16, 1) 
	                      	RETURN -108
	                END

			SELECT @qty_to_move = @qty - (@in_stock - @alloc_qty)

			-- Check to see if there is enough inventory that is not tx_locked in queue
			IF (	SELECT ISNULL(SUM(qty_to_process), 0)
					FROM tdc_pick_queue (NOLOCK)
					WHERE location = @loc
					AND part_no = @part
					AND lot = @lot_ser 
					AND bin_no = @from_bin
					AND tx_lock in ('R', 'G')
					AND trans NOT IN ( 'PLWB2B', 'MGTB2B' )
					AND (	--This monster of a clause makes sure that we dont consider
						(	trans in ('STDPICK', 'PKGBLD')	--allocations with pick-tickets.
							AND (	NOT EXISTS ( SELECT * 
									FROM tdc_print_history_tbl 
									WHERE order_no = tdc_pick_queue.trans_type_no
									AND order_ext = tdc_pick_queue.trans_type_ext
									AND location = tdc_pick_queue.location
									AND pick_ticket_type = 'S' )
								OR (	SELECT Status 
									FROM orders 
									WHERE order_no = tdc_pick_queue.trans_type_no
									AND ext = tdc_pick_queue.trans_type_ext) = 'N'
							)
						) OR (	trans='WOPPICK' 
							AND (	NOT EXISTS ( SELECT * 
									FROM tdc_print_history_tbl 
									WHERE order_no = tdc_pick_queue.trans_type_no
									AND order_ext = tdc_pick_queue.trans_type_ext
									AND location = tdc_pick_queue.location 
									AND pick_ticket_type = 'W' )
								OR (	SELECT Status 
									FROM produce 
									WHERE prod_no = tdc_pick_queue.trans_type_no
									AND prod_ext = tdc_pick_queue.trans_type_ext ) = 'N'
							)
						
						) OR (	trans='XFERPICK' 
							AND (	NOT EXISTS ( SELECT * 
									FROM tdc_print_history_tbl 
									WHERE order_no = tdc_pick_queue.trans_type_no
									AND location = tdc_pick_queue.location
									AND pick_ticket_type = 'X'  )
								OR (	SELECT Status 
									FROM xfers 
									WHERE xfer_no = tdc_pick_queue.trans_type_no ) = 'N'
							)
						
						)
					)
				) < @qty_to_move
			BEGIN
	                      	-- UPDATE #adm_bin_xfer SET err_msg = 'Inventory locked in pending queue transaction' WHERE row_id = @issid
				ROLLBACK TRAN
				SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -109 AND language = @language
				RAISERROR (@msg, 16, 1) 
	                      	RETURN -109
	                END

			WHILE @qty_to_move > 0
			BEGIN
				-- Get the most recent queue entry
				SELECT TOP 1 	@subqty = qty_to_process,
						@tran_id = tran_id,
						@order_no = trans_type_no,
						@order_ext = trans_type_ext,
						@order_line = line_no
					FROM tdc_pick_queue
					WHERE location = @loc
						AND part_no = @part 
						AND lot = @lot_ser 
						AND bin_no = @from_bin
						AND tx_lock in ('R', 'G')
						AND trans NOT IN ( 'PLWB2B', 'MGTB2B' )
						AND (	--This monster of a clause makes sure that we dont consider
							(	trans in ('STDPICK', 'PKGBLD') 	--allocations with pick-tickets.
								AND (	NOT EXISTS ( SELECT * 
										FROM tdc_print_history_tbl 
										WHERE order_no = tdc_pick_queue.trans_type_no
										AND order_ext = tdc_pick_queue.trans_type_ext
										AND location = tdc_pick_queue.location
										AND pick_ticket_type = 'S' )
									OR (	SELECT Status 
										FROM orders 
										WHERE order_no = tdc_pick_queue.trans_type_no
										AND ext = tdc_pick_queue.trans_type_ext) = 'N'
								)
							) OR (	trans='WOPPICK' 
								AND (	NOT EXISTS ( SELECT * 
										FROM tdc_print_history_tbl 
										WHERE order_no = tdc_pick_queue.trans_type_no
										AND order_ext = tdc_pick_queue.trans_type_ext
										AND location = tdc_pick_queue.location 
										AND pick_ticket_type = 'W' )
									OR (	SELECT Status 
										FROM produce 
										WHERE prod_no = tdc_pick_queue.trans_type_no
										AND prod_ext = tdc_pick_queue.trans_type_ext ) = 'N'
								)
							
							) OR (	trans='XFERPICK' 
								AND (	NOT EXISTS ( SELECT * 
										FROM tdc_print_history_tbl 
										WHERE order_no = tdc_pick_queue.trans_type_no
										AND location = tdc_pick_queue.location
										AND pick_ticket_type = 'X'  )
									OR (	SELECT Status 
										FROM xfers 
										WHERE xfer_no = tdc_pick_queue.trans_type_no ) = 'N'
								)
							
							)
						)
					ORDER BY date_time DESC

				-- If we only need to move some of the queue entry
				IF @qty_to_move < @subqty
				BEGIN
					SELECT @subqty = @qty_to_move
				END

				-- Check to see if there is already an entry in softalloc
				--	for this order/ext/line/lot at @to_bin
				IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl 
					WHERE location = @loc
					AND order_no = @order_no
					AND order_ext = @order_ext
					AND line_no = @order_line
					AND lot_ser = @lot_ser
					AND bin_no = @to_bin)
				BEGIN
					-- Update qty, trg_off in softalloc for pre-existing entry
					UPDATE tdc_soft_alloc_tbl
						SET 	qty = qty + @subqty
						WHERE location = @loc
						AND order_no = @order_no
						AND order_ext = @order_ext
						AND line_no = @order_line
						AND lot_ser = @lot_ser
						AND bin_no = @to_bin
				END
				ELSE
				BEGIN
					-- Insert into softalloc, duplicate record except bin, targetbin, and qty
					INSERT INTO tdc_soft_alloc_tbl 
						(order_no, order_ext, location, line_no, part_no, lot_ser,
							bin_no, qty, target_bin, dest_bin, trg_off, order_type,
							assigned_user, alloc_type, q_priority)
						(SELECT order_no, order_ext, location, line_no, part_no, lot_ser,
							@to_bin, @subqty, @to_bin, dest_bin, 0, order_type,
							assigned_user, alloc_type, @q_priority
						FROM tdc_soft_alloc_tbl
						WHERE	location = @loc
							AND order_no = @order_no
							AND order_ext = @order_ext
							AND line_no = @order_line
							AND bin_no = @from_bin
							AND lot_ser = @lot_ser)
				END

				-- Update qty, trg_off for old softalloc entry
				UPDATE	tdc_soft_alloc_tbl
				SET 	qty = qty - @subqty
				WHERE	location = @loc
					AND order_no = @order_no
					AND order_ext = @order_ext
					AND line_no = @order_line
					AND bin_no = @from_bin
					AND lot_ser = @lot_ser

				SELECT @qty_to_move = @qty_to_move - @subqty
			END --WHILE
		END --IF @in_stock - @alloc_qty < @qty
	END

	EXEC @err = tdc_bin_xfer
	IF @err > 0 COMMIT TRAN
	ELSE ROLLBACK TRAN

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_bintobin_xfer] TO [public]
GO
