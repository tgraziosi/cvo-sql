SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_autopick_transfer_sp] (@xfer_no INT,  @user_id varchar(50))
AS
BEGIN
	DECLARE @tran_id INT

	-- Check if transfer is set to autopack or autoship
	IF NOT EXISTS (SELECT 1 FROM dbo.xfers WHERE xfer_no = @xfer_no AND (autopack = 1 OR autoship = 1))
	BEGIN
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
		EXEC dbo.cvo_autopick_transfer_line_sp @tran_id,@user_id
		
	END
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_autopick_transfer_sp] TO [public]
GO
