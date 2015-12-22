SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 18/10/2012 - Process record in the CVO_autopack_transfer table
/*
Processed values:
0 = New record, not processed
2 = Processed
-1 = Marked for processing
-2 = being processed
*/
CREATE PROC [dbo].[CVO_process_autopack_transfer_sp]
AS
BEGIN
	DECLARE @rec_id		INT,
			@xfer_no	INT,
			@user_id	VARCHAR(50),
			@processed	INT,
			@valid		SMALLINT 

	-- Delete any records processed in the previous run
	DELETE FROM
		dbo.CVO_autopack_transfer
	WHERE 
		processed = 2
	
	-- Update all records to show they are being processed
	UPDATE 
		dbo.CVO_autopack_transfer
	SET
		processed = -1
	WHERE 
		processed IN (0,-1,-2)

	-- Loop through records and process them
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@xfer_no = xfer_no,
			@user_id = proc_user_id
		FROM
			dbo.CVO_autopack_transfer (NOLOCK)
		WHERE
			rec_id > @rec_id
			AND processed = -1
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		SET @valid = 1 -- true

		-- Check autopack is on for this transfer
		IF NOT EXISTS (SELECT 1 FROM dbo.xfers_all WHERE xfer_no = @xfer_no AND ISNULL(autopack,0) = 1)
		BEGIN
			SET @valid = 0
		END

		-- Check it's not void
		IF EXISTS (SELECT 1 FROM dbo.xfers_all WHERE xfer_no = @xfer_no AND [status] = 'V')
		BEGIN
			SET @valid = 0
		END		

		IF @valid = 1
		BEGIN
			EXEC dbo.cvo_autopick_transfer_sp @xfer_no, @user_id
		END
		SET @processed = 2

		-- Update record to show that it is processed
		UPDATE
			dbo.CVO_autopack_transfer
		SET
			processed = @processed,
			processed_date = GETDATE()
		WHERE
			rec_id = @rec_id
	END

END

GO
GRANT EXECUTE ON  [dbo].[CVO_process_autopack_transfer_sp] TO [public]
GO
