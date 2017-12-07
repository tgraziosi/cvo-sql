SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_sim_process_custom_kit_sp]	@order_no int,
												@order_ext int,
												@line_no int,
												@process int,
												@consolidation_no int = 0
AS
BEGIN
	-- NOTE: Routine based on cvo_process_custom_kit_sp v1.0 - All changes must be kept in sync

	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @part_no	varchar(30),
			@location	varchar(10),
			@ordered	decimal(20,8),
			@seq_no		int,
			@priority	int,
			@next_op	varchar(20)			

	-- PROCESSING
	IF (@process = 0) -- Create pick queue for custom kit
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans_source = 'PLW' AND trans = 'STDPICK' AND trans_type_no = @order_no
						AND trans_type_ext = @order_ext AND line_no = @line_no AND ISNULL(company_no,'') <> 'CF')
			RETURN

		IF NOT EXISTS (SELECT 1 FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans_source = 'PLW' AND trans = 'STDPICK' AND trans_type_no = @order_no
						AND trans_type_ext = @order_ext AND line_no = @line_no AND ISNULL(company_no,'') = 'CF')
		BEGIN
			SELECT @priority = value_str FROM tdc_config where [function] = 'Pick_Q_Priority' 
			IF (@priority IS NULL OR @priority = 0)
				SET @priority = 5 

			SELECT @seq_no = MAX(seq_no) + 1 FROM #sim_tdc_pick_queue

			SELECT	@next_op = next_op
			FROM	#sim_tdc_pick_queue (NOLOCK)
			WHERE	trans_type_no = @order_no
			AND		trans_type_ext = @order_ext
			AND		line_no = @line_no
			AND		trans = 'STDPICK'
		            
			INSERT INTO #sim_tdc_pick_queue (trans_source, trans,  priority,  seq_no, company_no, location, warehouse_no, trans_type_no, trans_type_ext,             
					tran_receipt_no, line_no, pcsn, part_no, eco_no, lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process,             
					qty_processed, qty_short, next_op, tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)            
			SELECT	'PLW', 'STDPICK', @priority, @seq_no, 'CF', location, NULL, @order_no, @order_ext, NULL, @line_no, NULL, part_no, NULL, '', NULL, NULL, NULL, 'CUSTOM',            
					ordered, 0, 0, @next_op, NULL, GETDATE(), 'SOPICKER', NULL, 'CUSTOM', NULL, NULL, 'M', 'H'
			FROM	ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
		            
		END
	END

	IF (@process = 1) -- Check for unpicked kit items and then release hold
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans_source = 'PLW' AND trans = 'STDPICK' AND trans_type_no = @order_no
						AND trans_type_ext = @order_ext AND line_no = @line_no AND ISNULL(company_no,'') <> 'CF')
		BEGIN
			UPDATE	#sim_tdc_pick_queue
			SET		user_id = NULL,
					tx_lock = 'R'
			WHERE	trans_source = 'PLW' 
			AND		trans = 'STDPICK' 
			AND		trans_type_no = @order_no
			AND		trans_type_ext = @order_ext 
			AND		line_no = @line_no 
			AND		ISNULL(company_no,'') = 'CF'
		END
	END

	IF (@process > 2) -- Picking custom kit 
	BEGIN

		DELETE	#sim_tdc_pick_queue
		WHERE	tran_id = @process

	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_sim_process_custom_kit_sp] TO [public]
GO
