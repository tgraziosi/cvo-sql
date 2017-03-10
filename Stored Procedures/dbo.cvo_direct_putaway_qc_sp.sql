SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_direct_putaway_qc_sp]	@receipt_no int,
											@po_no varchar(20),
											@scrap_qty decimal(20,8)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@qty_remaining	decimal(20,8),
			@tran_id		int,
			@qty			decimal(20,8)

	--PROCESSING
	IF (@scrap_qty = 0)
	BEGIN
		UPDATE  tdc_put_queue
		SET		tx_lock = 'R'
		WHERE	trans_type_no = @po_no
		AND		tran_receipt_no = @receipt_no

		RETURN
	END

	-- Remove in reverse order
	-- No Bin Specified
	SET @tran_id = NULL
	SELECT	@tran_id = tran_id,
			@qty = qty_to_process
	FROM	tdc_put_queue (NOLOCK)
	WHERE	trans_type_no = @po_no
	AND		tran_receipt_no = @receipt_no
	AND		next_op = ''
	AND		warehouse_no IS NOT NULL

	IF (@tran_id IS NOT NULL)
	BEGIN
		IF (@qty > @scrap_qty)
		BEGIN
			UPDATE	tdc_put_queue
			SET		qty_to_process = qty_to_process - @scrap_qty,
					tx_lock = 'R'
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty = @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty < @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id
	
			SET @scrap_qty = @scrap_qty - @qty
		END
	END

	-- Bulk 
	SET @tran_id = NULL
	SELECT	@tran_id = a.tran_id,
			@qty = a.qty_to_process
	FROM	tdc_put_queue a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.next_op = b.bin_no
	WHERE	a.trans_type_no = @po_no
	AND		a.tran_receipt_no = @receipt_no
	AND		b.group_code = 'BULK'
	AND		a.warehouse_no IS NOT NULL

	IF (@tran_id IS NOT NULL)
	BEGIN
		IF (@qty > @scrap_qty)
		BEGIN
			UPDATE	tdc_put_queue
			SET		qty_to_process = qty_to_process - @scrap_qty,
					tx_lock = 'R'
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty = @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty < @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id
	
			SET @scrap_qty = @scrap_qty - @qty
		END
	END

	-- Highbay
	SET @tran_id = NULL
	SELECT	@tran_id = a.tran_id,
			@qty = a.qty_to_process
	FROM	tdc_put_queue a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.next_op = b.bin_no
	WHERE	a.trans_type_no = @po_no
	AND		a.tran_receipt_no = @receipt_no
	AND		b.group_code = 'HIGHBAY'
	AND		a.warehouse_no IS NOT NULL

	IF (@tran_id IS NOT NULL)
	BEGIN
		IF (@qty > @scrap_qty)
		BEGIN
			UPDATE	tdc_put_queue
			SET		qty_to_process = qty_to_process - @scrap_qty,
					tx_lock = 'R'
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty = @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty < @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id
	
			SET @scrap_qty = @scrap_qty - @qty
		END
	END
	
	-- Fast Track
	SET @tran_id = NULL
	SELECT	@tran_id = a.tran_id,
			@qty = a.qty_to_process
	FROM	tdc_put_queue a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.next_op = b.bin_no
	WHERE	a.trans_type_no = @po_no
	AND		a.tran_receipt_no = @receipt_no
	AND		LEFT(a.next_op,4) = 'ZZZ-'
	AND		a.warehouse_no IS NOT NULL

	IF (@tran_id IS NOT NULL)
	BEGIN
		IF (@qty > @scrap_qty)
		BEGIN
			UPDATE	tdc_put_queue
			SET		qty_to_process = qty_to_process - @scrap_qty,
					tx_lock = 'R'
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty = @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty < @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id
	
			SET @scrap_qty = @scrap_qty - @qty
		END
	END

	-- Forward Pick
	SET @tran_id = NULL
	SELECT	@tran_id = a.tran_id,
			@qty = a.qty_to_process
	FROM	tdc_put_queue a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.next_op = b.bin_no
	WHERE	a.trans_type_no = @po_no
	AND		a.tran_receipt_no = @receipt_no
	AND		b.group_code = 'PICKAREA'
	AND		a.warehouse_no IS NOT NULL

	IF (@tran_id IS NOT NULL)
	BEGIN
		IF (@qty > @scrap_qty)
		BEGIN
			UPDATE	tdc_put_queue
			SET		qty_to_process = qty_to_process - @scrap_qty,
					tx_lock = 'R'
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty = @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty < @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id
	
			SET @scrap_qty = @scrap_qty - @qty
		END
	END

	-- Reserve
	SET @tran_id = NULL
	SELECT	@tran_id = a.tran_id,
			@qty = a.qty_to_process
	FROM	tdc_put_queue a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.next_op = b.bin_no
	WHERE	a.trans_type_no = @po_no
	AND		a.tran_receipt_no = @receipt_no
	AND		b.group_code = 'RESERVE'
	AND		a.warehouse_no IS NOT NULL

	IF (@tran_id IS NOT NULL)
	BEGIN
		IF (@qty > @scrap_qty)
		BEGIN
			UPDATE	tdc_put_queue
			SET		qty_to_process = qty_to_process - @scrap_qty,
					tx_lock = 'R'
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty = @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty < @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id
	
			SET @scrap_qty = @scrap_qty - @qty
		END
	END

	-- If any scrap and transactions left they are backorder processing
	SET @tran_id = NULL
	SELECT	@tran_id = a.tran_id,
			@qty = a.qty_to_process
	FROM	tdc_put_queue a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.next_op = b.bin_no
	WHERE	a.trans_type_no = @po_no
	AND		a.tran_receipt_no = @receipt_no
	AND		a.warehouse_no IS NULL

	IF (@tran_id IS NOT NULL)
	BEGIN
		IF (@qty > @scrap_qty)
		BEGIN
			UPDATE	tdc_put_queue
			SET		qty_to_process = qty_to_process - @scrap_qty,
					tx_lock = 'R'
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty = @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id

			UPDATE  tdc_put_queue
			SET		tx_lock = 'R'
			WHERE	trans_type_no = @po_no
			AND		tran_receipt_no = @receipt_no

			RETURN
		END
		IF (@qty < @scrap_qty)
		BEGIN
			DELETE	tdc_put_queue
			WHERE	tran_id = @tran_id
	
			SET @scrap_qty = @scrap_qty - @qty
		END
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_direct_putaway_qc_sp] TO [public]
GO
