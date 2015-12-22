SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 18/10/2012 - Process record in the CVO_auto_receive_credit_return table
-- v1.1 CB 28/07/2015 - Add another step for writing tdc log only when stock actually received (credit return posting)
/*
Processed values:
0 = New record, not processed
1 = Order on user hold
2 = Processed
3 = Received -- v1.1
-1 = Marked for processing
-2 = being processed
*/
CREATE PROC [dbo].[CVO_process_auto_receive_credit_return_sp]
AS
BEGIN
	DECLARE @rec_id		INT,
			@order_no	INT,
			@ext		INT,
			@processed	INT

	-- Delete any records processed in the previous run
	DELETE FROM
		dbo.CVO_auto_receive_credit_return
	WHERE 
		processed = 3 -- v1.1 2
	
	-- Update all records to show they are being processed
	UPDATE 
		dbo.CVO_auto_receive_credit_return
	SET
		processed = -1
	WHERE 
		processed IN (1,0,-1,-2)

	-- Loop through records and process them
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext
		FROM
			dbo.CVO_auto_receive_credit_return (NOLOCK)
		WHERE
			rec_id > @rec_id
			AND processed = -1
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Check credit isn't on user hold
		IF NOT EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND [status] = 'A')
		BEGIN
			EXEC dbo.CVO_auto_receive_credit_return_sp @order_no, @ext
			SET @processed = 2
		END
		ELSE
		BEGIN
			SET @processed = 1 
		END
		-- Update record to show that it is processed
		UPDATE
			dbo.CVO_auto_receive_credit_return
		SET
			processed = @processed,
			processed_date = GETDATE()
		WHERE
			rec_id = @rec_id
	END

END
GO
