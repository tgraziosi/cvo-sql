SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_AdhocReceiptPutaway]
AS

	DECLARE @Priority as int, 
		@SeqNo as int,
		@trans as int,
		@location as varchar(10),
		@item as varchar(30),
		@lot as varchar(25),
		@bin as varchar(12),
		@qty as decimal(20,8),
		@ExpiredDate as datetime,
		@RecDate as datetime,
		@Id as int,
		@Value as varchar(40),
		@Active as char(1),
		@Month as int,
		@err as int,
		@err_msg as varchar(255),
		@language varchar(10)
	

	SELECT @err = 0
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT MIN(who_entered) FROM #adm_inv_adj)), 'us_english')

BEGIN TRAN

	-- Find Expiration Date
	DECLARE line_cursor CURSOR FOR SELECT loc, part_no, bin_no, lot_ser, date_exp, row_id FROM #adm_inv_adj
	OPEN line_cursor
	FETCH NEXT FROM line_cursor INTO @location, @item, @bin, @lot, @RecDate, @Id
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF EXISTS (SELECT * FROM lot_bin_stock (nolock) WHERE part_no = @item and bin_no = @bin 
				AND lot_ser = @lot and location = @location)
		BEGIN
			SELECT @ExpiredDate = date_expires FROM lot_bin_stock (nolock)
						WHERE part_no = @item AND lot_ser = @lot
						AND location = @location	
		END
		ELSE
		BEGIN
			SELECT @ExpiredDate = CONVERT(varchar(20), dateadd(mm, 12, @RecDate), 109)
		END
		
		UPDATE #adm_inv_adj SET date_exp = @ExpiredDate WHERE row_id = @Id

		FETCH NEXT FROM line_cursor INTO @location, @item, @bin, @lot, @RecDate, @Id
	END
	DEALLOCATE line_cursor

	EXEC @err = tdc_adm_inv_adj

	IF @err < 0
	BEGIN
	--	error message should be displayed when stored procedure tdc_inv_adj is called
	--	SELECT @err_msg = (SELECT MAX(err_msg) FROM #adm_inv_adj)
	    	ROLLBACK TRAN
	--    	UPDATE #adm_inv_adj SET err_msg = @err_msg
	    	RETURN @err
	END

	--Process Generate Pick Transaction
	SELECT @Priority = 5

	DECLARE adhoc_cursor CURSOR FOR SELECT adj_no, loc, part_no, lot_ser, bin_no, qty FROM #adm_inv_adj
	OPEN adhoc_cursor
	FETCH NEXT FROM adhoc_cursor INTO @trans, @location, @item, @lot, @bin, @qty

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF EXISTS(SELECT * FROM inv_master (nolock) WHERE part_no = @item AND lb_tracking = 'Y')
		BEGIN
			EXEC @SeqNo = tdc_queue_get_next_seq_num  'tdc_put_queue', @Priority 
 
			IF (@SeqNo = 0) 
			BEGIN
				ROLLBACK TRAN
			--	UPDATE #adm_inv_adj SET err_msg = 'Error Invalid Sequence or Trans Id or Priority.'
 				SELECT @err_msg = err_msg 
					FROM tdc_lookup_error (nolock)
						WHERE module = 'SPR' AND trans = 'tdc_adh_rec_putaway_sp' AND err_no = -200 AND language = @language
				RAISERROR (@err_msg, 16, 1)
				RETURN -200
			END


			INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, location,
	       			trans_type_no, part_no,lot, bin_no, qty_to_process, qty_processed, qty_short,
				date_time, assign_group, tx_control, tx_lock)
				VALUES('ADHRE', 'ADHRECB2B', @Priority ,  @SeqNo  , @location ,  
					@trans, @item ,@lot, @bin, @qty, 0.0, 0.0, getdate(), 'PUTAWAY', 'M', 'R')
		END

		FETCH NEXT FROM adhoc_cursor INTO @trans, @location, @item, @lot, @bin, @qty
	END
	DEALLOCATE adhoc_cursor

COMMIT TRAN

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_AdhocReceiptPutaway] TO [public]
GO
