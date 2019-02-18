SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_autopick_transfer_sp] (@xfer_no INT,  @user_id varchar(50))
AS
BEGIN

	SET NOCOUNT ON -- v1.1

	DECLARE @tran_id INT

	-- Check if transfer is set to autopack or autoship
	IF NOT EXISTS (SELECT 1 FROM dbo.xfers WHERE xfer_no = @xfer_no AND (autopack = 1 OR autoship = 1))
	BEGIN
		-- v1.2 Start
		INSERT	dbo.cvo_transfer_pick_pack_log (log_date, xfer_no, log_message)
		SELECT	GETDATE(), @xfer_no, 'Transfer not flagged as autopack - Exiting cvo_autopick_transfer_sp'
		-- v1.2 End
		RETURN
	END
	
	SET @tran_id = 0
	
	-- Loop through pick queue records for the transfer
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@tran_id = tran_id
		FROM 
			dbo.tdc_pick_queue (NOLOCK)
		WHERE
			tran_id > @tran_id
			AND tx_lock = 'R' 
			AND trans_type_no = @xfer_no
			AND trans_source = 'PLW'
			AND trans = 'XFERPICK'
		ORDER BY 
			tran_id

		IF @@ROWCOUNT = 0
			BREAK
		
		-- Pick the record
		-- v1.2 Start
		INSERT	dbo.cvo_transfer_pick_pack_log (log_date, xfer_no, log_message)
		SELECT	GETDATE(), @xfer_no, 'Calling cvo_autopick_transfer_line_sp for tran_id: ' + CAST(@tran_id as varchar(20))
		-- v1.2 End
		EXEC dbo.cvo_autopick_transfer_line_sp @tran_id,@user_id
		
	END
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_autopick_transfer_sp] TO [public]
GO
