SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_email_ship_confirmation_sp
-- 2/2/18 - remove co@cvoptical.com

CREATE PROC [dbo].[cvo_email_ship_confirmation_sp]  
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
			@attachment		varchar(5000), -- v1.1
			@order_no		int,
			@order_ext		int,
			@doc_ctrl_num	varchar(16),
			@tracking_url	varchar(255), --v1.2
			@tracking_no    VARCHAR(255),
			@cons_no		int, -- v1.1
			@c_order_no		int, -- v1.1
			@c_order_ext	int, -- v1.1
			@last_c_order_no int, -- v1.1
			@cons_attachment varchar(1000) -- v1.1

	-- Processing
	SELECT	@tracking_url = value_str
	FROM	dbo.config (NOLOCK) 
	WHERE	flag = 'OE_TRACKING_NO_URL'

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
	AND		etype = 0
	AND		row_id > @last_row_id

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		-- v1.1 Start
		SET @cons_no = 0

		SELECT	@cons_no = consolidation_no
		FROM	cvo_masterpack_consolidation_det (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		-- v1.1 End
			
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
			AND		etype = 0
			AND		row_id > @last_row_id

			CONTINUE
		END

		-- v1.1 Start
		IF (ISNULL(@cons_no,0) > 0)
		BEGIN	

			SET @attachment = ''

			SELECT	@c_order_no = MIN(a.order_no)					
			FROM	cvo_email_ship_confirmation a (NOLOCK)
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			WHERE	b.consolidation_no = @cons_no

			-- Set email subject and body text
			-- v1.2
			SET @subject_line = 'Your ClearVision Order Shipment Notice - ' + CAST(@cons_no AS varchar(20)) + '.'
			SET @body_text = '<img src="https://s3.amazonaws.com/cvo-email-media/logo.png" alt="ClearVision Optical Company"><BR><BR>'
			SET @body_text = @body_text + 'Congratulations, your order(s) are on the way! <BR><BR>'
			SET @body_text = @body_text + 'Attached are copies of your invoices. <BR><BR>'
			-- SET @body_text = @body_text + 'Tracking information below. <BR>'
			-- v1.2

			SET @last_c_order_no = @c_order_no - 1

			SELECT	TOP 1 @c_order_no = a.order_no,
					@c_order_ext = a.order_ext,
					@cons_attachment = a.inv_created
			FROM	cvo_email_ship_confirmation a (NOLOCK)
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			WHERE	b.consolidation_no = @cons_no	
			AND		a.order_no > @last_c_order_no
			ORDER BY a.order_no ASC

			WHILE (@@ROWCOUNT <> 0)
			BEGIN
				-- v1.2
				SELECT TOP (1) @tracking_url = dbo.f_cvo_get_tracking_url(cs_tracking_no, carrier_code), @tracking_no = cs_tracking_no
				FROM	tdc_carton_tx (NOLOCK) CTN
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND  ctn.status = 'X'

				IF ISNULL(@tracking_no,'') >''
				begin
				Select @body_text = @body_text + 'Tracking for Order No: ' + CAST(@c_order_no AS VARCHAR(20)) + ' - ' + '<a href="' + @tracking_url + '">' + @tracking_no  + '</a><BR>'
				END		
				-- v1.2		

				IF (@attachment = '')
					SET @attachment = @cons_attachment
				ELSE
					SET @attachment = @attachment + ';' + @cons_attachment			

				SET @last_c_order_no = @c_order_no

				SELECT	TOP 1 @c_order_no = a.order_no,
						@c_order_ext = a.order_ext,
						@cons_attachment = a.inv_created
				FROM	cvo_email_ship_confirmation a (NOLOCK)
				JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				WHERE	b.consolidation_no = @cons_no	
				AND		a.order_no > @last_c_order_no
				ORDER BY a.order_no ASC

			END

			UPDATE	a
			SET		email_sent = 1,
					sent_date = GETDATE()
			FROM	cvo_email_ship_confirmation a
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			WHERE	b.consolidation_no = @cons_no		

		END
		ELSE
		BEGIN
		-- v1.2
			-- Set email subject and body text
			SET @subject_line = 'Your ClearVision Order Shipment Notice - ' + CAST(@order_no AS varchar(20)) + '.'

			SET @body_text = '<img src="https://s3.amazonaws.com/cvo-email-media/logo.png" alt="ClearVision Optical Company"><BR><BR>'
			SET @body_text = @body_text + '<font face = "verdana"> <h2 style="color:#025a89">Congratulations, your order is on its way!</h2> <BR><BR>'
			SET @body_text = @body_text + 'Attached is a copy of your invoice. <BR><BR>'


			--SELECT	@body_text = @body_text + '<a href="' + @tracking_url + cs_tracking_no + '">' + @tracking_url + cs_tracking_no + '</a><BR>'
			--FROM	tdc_carton_tx (NOLOCK)
			--WHERE	order_no = @order_no
			--AND		order_ext = @order_ext

			SELECT TOP (1) @tracking_url = dbo.f_cvo_get_tracking_url(cs_tracking_no, carrier_code), @tracking_no = cs_tracking_no
			FROM	tdc_carton_tx (NOLOCK) CTN
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND  ctn.status = 'X'

			IF ISNULL(@tracking_no,'') >''
			begin
			SElect @body_text = @body_text + 'Here is your Tracking number: <BR>'
			SELECT @body_text = @body_text + '<a href="' + @tracking_url + + '">' + @tracking_no  + '</a><BR>'
			END
			-- v1.2
		END
		-- v1.1 End

		--v1.2
		SET @body_text = @body_text + '<BR><BR>Thanks again for ordering from CVO!<BR><BR>'	
		SET @body_text = @body_text + 'ClearVision Optical Company<BR>'
		SET @body_text = @body_text + '425 Rabro Drive, Suite 2<BR>'
		SET @body_text = @body_text + 'Hauppauge, NY 11788<BR>'
		SET @body_text = @body_text + '1.800.645.3733 WWW.CVOPTICAL.COM<BR> </font>'
		--v1.2

		IF (@@servername <> 'V227230K') -- for Epicor Testing
		BEGIN
			IF (@@servername <> 'cvo-db-03') -- for testing
			BEGIN
				--SET @email_address = 'cboston@epicor.com'
				SET @email_address = 'tgraziosi@cvoptical.com'
				SET @subject_line = @subject_line + ' - TESTING'

				EXEC @rc = msdb.dbo.sp_send_dbmail
						 @recipients = @email_address,
						 -- @blind_copy_recipients = 'co@cvoptical.com', --v1.2
						 @body = @body_text, 
						 @subject = @subject_line,
						 @file_attachments = @attachment,
						 @body_format = 'HTML',
						 @profile_name = 'OrderConfirmations' --v1.2
			END
			ELSE
			BEGIN
				-- Call SQL email routine
				EXEC @rc = msdb.dbo.sp_send_dbmail
						 @recipients = @email_address,
						 -- @blind_copy_recipients = 'co@cvoptical.com', --v1.2
						 @body = @body_text, 
						 @subject = @subject_line,
						 @file_attachments = @attachment,
						 @body_format = 'HTML',
						 @profile_name = 'OrderConfirmations' --v1.2
			END		
		END
		ELSE
		BEGIN
			SELECT '@recipients',@email_address
			SELECT '@subject',@subject_line	
			SELECT '@body',@body_text
			SELECT '@file_attachments',@attachment
		END

		-- v1.1 Start
		IF (ISNULL(@cons_no,0) = 0)
		BEGIN
			UPDATE	cvo_email_ship_confirmation
			SET		email_sent = 1,
					sent_date = GETDATE()
			WHERE	row_id = @row_id
		END
		-- v1.1 End

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
		AND		etype = 0
		AND		row_id > @last_row_id

	END
END

GO
GRANT EXECUTE ON  [dbo].[cvo_email_ship_confirmation_sp] TO [public]
GO
