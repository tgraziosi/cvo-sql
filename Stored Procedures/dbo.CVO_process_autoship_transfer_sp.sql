SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 18/10/2012 - Process record in the CVO_process_autoship_transfer_sp table
/*
Processed values:
0 = New record, not processed
2 = Processed
-1 = Marked for processing
-2 = Being processed
99 = Error

Step values:
0 = Awaiting allocation
1 = Awaiting pick/pack
2 = Awaiting carton close/stage
3 = Awaiting carton ship
4 = Complete
5 = Autoship no longer checked on transfer/transfer void
*/
CREATE PROC [dbo].[CVO_process_autoship_transfer_sp]
AS
BEGIN
	DECLARE @rec_id		INT,
			@xfer_no	INT,
			@user_id	VARCHAR(50),
			@processed	INT,
			@step		INT,
			@retval		INT,
			@valid		SMALLINT

	-- Delete any records completely processed in the previous run
	DELETE FROM
		dbo.CVO_autoship_transfer
	WHERE 
		processed = 2
		AND proc_step >= 4
	
	-- Update all records to show they are being processed
	UPDATE 
		dbo.CVO_autoship_transfer
	SET
		processed = -1
	WHERE 
		processed IN (0,-1,-2)

	-- Loop through steps in order and process them
	SET @step = -1
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@step = proc_step 
		FROM
			dbo.CVO_autoship_transfer (NOLOCK)
		WHERE
			proc_step > @step
			AND processed = -1
			AND proc_step < 4 -- don't pick up complete ones
			AND proc_step > 0 -- don't pick up awaiting allocation
		ORDER BY
			proc_step

		IF @@ROWCOUNT = 0
			BREAK

		-- Loop through records for this step
		SET @rec_id = 0
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@rec_id = rec_id,
				@xfer_no = xfer_no,
				@user_id = proc_user_id
			FROM
				dbo.CVO_autoship_transfer (NOLOCK)
			WHERE
				rec_id > @rec_id
				AND processed = -1
				AND proc_step = @step
			ORDER BY
				rec_id

			IF @@ROWCOUNT = 0
				BREAK

			SET @valid = 1 -- true

			-- Check it's marked as autoship
			IF NOT EXISTS (SELECT 1 FROM dbo.xfers_all WHERE xfer_no = @xfer_no AND ISNULL(autoship,0) = 1)
			BEGIN
				SET @valid = 0
			END

			-- Check it's not void
			IF EXISTS (SELECT 1 FROM dbo.xfers_all WHERE xfer_no = @xfer_no AND [status] = 'V')
			BEGIN
				SET @valid = 0
			END

			IF @valid = 0
			BEGIN
				-- Mark as complete 
				UPDATE
					dbo.CVO_autoship_transfer
				SET
					processed = 2,
					proc_step = 4
				WHERE
					rec_id = @rec_id
			END
			ELSE 
			BEGIN
				-- Pick/Pack
				IF @step = 1
				BEGIN
					SET @retval = -1
					EXEC @retval = dbo.cvo_autopick_transfer_sp @xfer_no, @user_id
					
					IF @retval < 0
					BEGIN
						-- Error
						SET @processed = 99
					END
					ELSE
					BEGIN
						-- Success
						SET @processed = -1
					END
				END
			
				-- Close/Stage
				IF @step = 2
				BEGIN
					SET @retval = -1
					EXEC @retval = dbo.cvo_close_stage_autoship_transfer_sp @xfer_no, @user_id, 999
					
					IF @retval < 0
					BEGIN
						-- Error
						SET @processed = 99
					END
					ELSE
					BEGIN
						-- Success
						SET @processed = -1
					END
				END
			
				-- Ship/Receive
				IF @step = 3
				BEGIN
					SET @retval = -1
					EXEC @retval = dbo.cvo_ship_autoship_transfer_sp @xfer_no, @user_id
					
					IF @retval < 0
					BEGIN
						-- Error
						SET @processed = 99
					END
					ELSE
					BEGIN
						-- Success
						SET @processed = 2
					END
				END


				-- Update record to show that it is processed
				UPDATE
					dbo.CVO_autoship_transfer
				SET
					processed = @processed,
					processed_date = GETDATE(),
					proc_step = CASE @processed WHEN 99 THEN proc_step ELSE proc_step + 1 END,
					error_no = CASE @processed WHEN 99 THEN @retval ELSE 0 END
				WHERE
					rec_id = @rec_id
			END
		END
	END
END	

GO
GRANT EXECUTE ON  [dbo].[CVO_process_autoship_transfer_sp] TO [public]
GO
