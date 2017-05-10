SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC cvo_email_customer_documents_sp
-- select * from cvo_autoemails
-- select sent_status,* from sysmail_allitems

CREATE PROC [dbo].[cvo_email_customer_documents_sp]
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@ae_id			int,
			@last_ae_id		int,
			@email_address	varchar(255),
			@subject_line	varchar(255),
			@body_text		varchar(5000),
			@attachment		varchar(500),
			@rc				int, 
			@mailitem_id	int

	-- Process each record in the queue
	UPDATE	cvo_autoemails
	SET		processed = -1
	WHERE	processed = 0

	SET	@last_ae_id = 0

	SELECT	TOP 1 @ae_id = ae_id,
			@email_address = email_address,
			@subject_line = subject_line,
			@body_text = body_text,
			@attachment = attachment
	FROM	cvo_autoemails 
	WHERE	processed = -1
	AND		ae_id > @last_ae_id
	ORDER BY ae_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Call SQL email routine
		SELECT @subject_line = REPLACE(@subject_line,'Invoice/Credit','Invoice/Credit ')
		SELECT @body_text = 'Thank you for choosing ClearVision Optical.  Please find attached your latest invoice/credit, as requested.  If you have any questions, please contact our accounting department at 800.645.3733.  Have a Fantastic day!'

		EXEC @rc = msdb.dbo.sp_send_dbmail
			 @recipients = @email_address,
			 @body = @body_text, 
			 @subject = @subject_line,
			 @profile_name = 'OrderConfirmations',
			 @file_attachments = @attachment,
			 @mailitem_id = @mailitem_id OUTPUT

		IF @rc <> 0
		BEGIN
			UPDATE	cvo_autoemails
			SET		processed = -2
			WHERE	ae_id = @ae_id
		END
		ELSE
		BEGIN
			UPDATE	cvo_autoemails
			SET		processed = 1
			WHERE	ae_id = @ae_id
		END
		

		SET	@last_ae_id = @ae_id

		SELECT	TOP 1 @ae_id = ae_id,
				@email_address = email_address,
				@subject_line = subject_line,
				@body_text = body_text,
				@attachment = attachment
		FROM	cvo_autoemails 
		WHERE	processed = -1
		AND		ae_id > @last_ae_id
		ORDER BY ae_id ASC

	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_email_customer_documents_sp] TO [public]
GO
