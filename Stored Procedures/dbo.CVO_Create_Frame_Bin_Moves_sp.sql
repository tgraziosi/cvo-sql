SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Create_Frame_Bin_Moves_sp] @order_no int, @order_ext int 
AS
BEGIN

	DECLARE	@tran_id		int,
			@last_tran_id	int,
			@bin_no			varchar(20),
			@custom_bin		varchar(20),
			@location		varchar(10),
			@part_no		varchar(30),
			@lot			varchar(20),
			@qty			decimal(20,8),
			@seqno			int,
			@priority		int,
			@line_no		int


	SELECT @custom_bin = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'CVO_CUSTOM_BIN'

	SELECT	@priority = ISNULL((SELECT value_str 
	FROM	tdc_config (NOLOCK)  
	WHERE	[function] = 'MGT_Pick_Q_Priority' AND active = 'Y'), 0)

	IF @priority = 0
		SET @priority = 5


	SET @last_tran_id = 0
	--SET @last_tran_id = 7656

	SELECT	TOP 1 @tran_id = a.tran_id,
			@location = a.location,
			@part_no = a.part_no,
			@lot = a.lot,
			@bin_no = a.bin_no,
			@qty = a.qty_to_process,
			@order_no = a.trans_type_no,
			@order_ext = a.trans_type_ext,
			@line_no = a.line_no
	FROM	tdc_pick_queue a (NOLOCK)
	JOIN	ord_list c (NOLOCK)
	ON		a.trans_type_no = c.order_no
	AND		a.trans_type_ext = c.order_ext
	AND		a.part_no = c.part_no
	AND		a.line_no = c.line_no
	JOIN	cvo_ord_list d (NOLOCK)
	ON		c.order_no = d.order_no
	AND		c.order_ext = d.order_ext
	AND		c.line_no = d.line_no
	WHERE	a.trans = 'STDPICK'
	AND		d.is_customized = 'S'
	AND		a.tran_id > @last_tran_id
	AND		a.trans_type_no = @order_no
	AND		a.trans_type_ext = @order_ext
	AND		c.part_type <> 'C' -- v1.3
	ORDER BY a.tran_id

	WHILE @@ROWCOUNT <> 0
	BEGIN


		IF NOT EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans = 'MGTB2B' AND trans_type_no = @order_no -- v1.4
						AND trans_type_ext = @order_ext AND line_no = @line_no AND part_no = @part_no)
		BEGIN

			INSERT INTO tdc_soft_alloc_tbl WITH (ROWLOCK) -- v1.4
						(order_type, order_no, order_ext, location, line_no, part_no,
						 lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)
			VALUES ('S', 0, 0, @location, 0, @part_no, 
						@lot, @bin_no, @qty, @custom_bin, @custom_bin, @priority)

			EXEC @seqno = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority 	

			INSERT INTO tdc_pick_queue WITH (ROWLOCK) (trans_source, trans, priority, seq_no, location, trans_type_no, -- v1.4
										trans_type_ext, line_no, part_no, eco_no, lot,qty_to_process, 
	       								qty_processed, qty_short,next_op, bin_no, date_time,assign_group, 
										tx_control, tx_lock, tran_id_link)
			VALUES ('MGT', 'MGTB2B', @priority, @seqno, @location,  @order_no,  @order_ext, @line_no, 
						@part_no, NULL, @lot, @qty, 0, 0, @custom_bin, @bin_no, GETDATE(), 'MGTB2B', 'M', 'R', @tran_id) 
		
		-- update pick queue record to pick from custom bin

			UPDATE	tdc_soft_alloc_tbl WITH (ROWLOCK) -- v1.4
			SET		bin_no = @custom_bin,
					target_bin = @custom_bin,
					trg_off = 1
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no

			UPDATE	tdc_pick_queue WITH (ROWLOCK) -- v1.4
			SET		tx_lock = 'H',
					mfg_lot = 2,
					bin_no = @custom_bin
			WHERE	tran_id = @tran_id

			-- v1.2
			UPDATE	a 
			SET		tx_lock = 'H',
					mfg_lot = 2,
					tran_id_link = @tran_id
			FROM	tdc_pick_queue a WITH (ROWLOCK) -- v1.4
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.trans_type_no = b.order_no
			AND		a.trans_type_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	a.trans = 'STDPICK'
			AND		a.trans_type_no = @order_no
			AND		a.trans_type_ext = @order_ext
			AND		b.from_line_no = @line_no
		

			UPDATE	tdc_soft_alloc_tbl WITH (ROWLOCK) -- v1.4
			SET		trg_off = 0
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
		END

		SET @last_tran_id = @tran_id

		SELECT	TOP 1 @tran_id = a.tran_id,
				@location = a.location,
				@part_no = a.part_no,
				@lot = a.lot,
				@bin_no = a.bin_no,
				@qty = a.qty_to_process,
				@order_no = a.trans_type_no,
				@order_ext = a.trans_type_ext,
				@line_no = a.line_no
		FROM	tdc_pick_queue a (NOLOCK)
		JOIN	ord_list c (NOLOCK)
		ON		a.trans_type_no = c.order_no
		AND		a.trans_type_ext = c.order_ext
		AND		a.part_no = c.part_no
		AND		a.line_no = c.line_no
		JOIN	cvo_ord_list d (NOLOCK)
		ON		c.order_no = d.order_no
		AND		c.order_ext = d.order_ext
		AND		c.line_no = d.line_no
		WHERE	a.trans = 'STDPICK'
		AND		d.is_customized = 'S'
		AND		a.tran_id > @last_tran_id
		AND		a.trans_type_no = @order_no
		AND		a.trans_type_ext = @order_ext
		AND		c.part_type <> 'C' -- v1.3
		ORDER BY a.tran_id


	END
END
GO
GRANT EXECUTE ON  [dbo].[CVO_Create_Frame_Bin_Moves_sp] TO [public]
GO
