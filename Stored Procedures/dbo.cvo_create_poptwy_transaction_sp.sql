SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_create_poptwy_transaction_sp] (	@location		VARCHAR(10),
													@po_no			VARCHAR(16),
													@receipt_no		INT,
													@part_no		VARCHAR(30),
													@lot			VARCHAR(25),
													@bin_no			VARCHAR(12),
													@next_op		VARCHAR(12),
													@qty			DECIMAL(20,8),
													@who			VARCHAR(50),
													@tran_id		INT OUTPUT,
													@direct			int = 0) -- v1.1
													
AS
BEGIN

	DECLARE @seq_no			INT, 
			@priority		INT,
			@assign_group	VARCHAR(30),
			@tx_lock		VARCHAR(2)

	SELECT @assign_group = 'PUTAWAY'  
	SELECT @tx_lock = 'R'  

	SELECT @priority = ISNULL((SELECT value_str FROM tdc_config (nolock) WHERE [function] = 'Put_Q_Priority'), '5')  
	IF @priority = '0' SELECT @priority = '5' 

	-- v1.1 Start
	IF (SELECT qc_flag FROM receipts (NOLOCK) WHERE receipt_no = @receipt_no AND part_no = @part_no) = 'Y'
		SELECT @tx_lock = 'Q'
	-- v1.1 End

	EXEC @seq_no = tdc_queue_get_next_seq_num  'tdc_put_queue', @priority 

	INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, company_no, location, warehouse_no,   
	   trans_type_no, trans_type_ext, tran_receipt_no, line_no, pcsn, part_no, eco_no,  
	   lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, next_op,  
	   tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)  
	  VALUES('CO', 'POPTWY', @priority, @seq_no, NULL, @location, CASE WHEN @direct = 1 THEN 'DIR' ELSE NULL END, -- v1.1 
		@po_no, NULL, @receipt_no, NULL, NULL, @part_no, NULL, @lot, NULL, NULL, NULL, @bin_no, @qty, 0, 0, @next_op,   
	   NULL, GETDATE(), @assign_group, NULL, @who, NULL, NULL, 'M', @tx_lock)  

	SET @tran_id = @@IDENTITY
END

GO
GRANT EXECUTE ON  [dbo].[cvo_create_poptwy_transaction_sp] TO [public]
GO
