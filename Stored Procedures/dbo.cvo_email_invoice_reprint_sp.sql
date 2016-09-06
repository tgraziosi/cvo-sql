SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_email_invoice_reprint_sp 1421327, 0, '035192', '', 'cboston@epicor.com'

CREATE PROC [dbo].[cvo_email_invoice_reprint_sp]  
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@subject_line	varchar(255),
			@body_text		varchar(max),
			@rc				int,
			@row_id			int,
			@last_row_id	int,
			@email_address	varchar(255),
			@attachment		varchar(1000),
			@order_no		int,
			@order_ext		int,
			@doc_ctrl_num	varchar(16)

	-- Processing
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@email_address = email_address,
			@doc_ctrl_num = doc_ctrl_num,
			@attachment = inv_created
	FROM	cvo_email_ship_confirmation (NOLOCK)
	WHERE	inv_created IS NOT NULL
	AND		email_sent = 0
	AND		etype = 1
	AND		row_id > @last_row_id

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
			
		-- Check email address passed in from the order
		-- If no email specified then use the customer/ship to record contact email
		IF (@email_address IS NULL)
			SET @email_address = ''

		IF (@email_address = '' OR PATINDEX('%@%',@email_address) = 0)
		BEGIN
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@email_address = email_address,
					@doc_ctrl_num = doc_ctrl_num,
					@attachment = inv_created
			FROM	cvo_email_ship_confirmation (NOLOCK)
			WHERE	inv_created IS NOT NULL
			AND		email_sent = 0
			AND		etype = 1
			AND		row_id > @last_row_id

			CONTINUE
		END

		-- Set email subject and body text
		SET @subject_line = 'Copy Invoice - ' + @doc_ctrl_num + '.'

		SET @body_text = 'Hello! <BR><BR>'
		SET @body_text = @body_text + 'Attached is a copy of your invoice as requested. <BR><BR>'

		SET @body_text = @body_text + 'Thank you for ordering from CVO!<BR><BR>'	
		SET @body_text = @body_text + '<i>ClearVision Optical</i><BR>'
		SET @body_text = @body_text + '<i>1.800.645.3733</i><BR>'
		SET @body_text = @body_text + '<i>425 Rabro Drive, Suite 2</i><BR>'
		SET @body_text = @body_text + '<i>Hauppauge, NY 11788</i><BR>'

		IF (@@servername <> 'V227230K') -- for Epicor Testing
		BEGIN
			IF (@@servername <> 'cvo-db-03') -- for testing
			BEGIN
				--SET @email_address = 'cboston@epicor.com'
				SET @email_address = 'tgraziosi@cvoptical.com'
				SET @subject_line = @subject_line + ' - TESTING'

				EXEC @rc = msdb.dbo.sp_send_dbmail
						 @recipients = @email_address,
						 @body = @body_text, 
						 @subject = @subject_line,
						 @file_attachments = @attachment,
						 @body_format = 'HTML',
						 @profile_name = 'OrderConfirmations'
			END
			ELSE
			BEGIN
				-- Call SQL email routine
				EXEC @rc = msdb.dbo.sp_send_dbmail
						 @recipients = @email_address,
						 @body = @body_text, 
						 @subject = @subject_line,
						 @file_attachments = @attachment,
						 @body_format = 'HTML',
						 @profile_name = 'OrderConfirmations'
			END
		END

		UPDATE	cvo_email_ship_confirmation
		SET		email_sent = 1,
				sent_date = GETDATE()
		WHERE	row_id = @row_id

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@email_address = email_address,
				@doc_ctrl_num = doc_ctrl_num,
				@attachment = inv_created
		FROM	cvo_email_ship_confirmation (NOLOCK)
		WHERE	inv_created IS NOT NULL
		AND		email_sent = 0
		AND		etype = 1
		AND		row_id > @last_row_id

	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_email_invoice_reprint_sp] TO [public]
GO
