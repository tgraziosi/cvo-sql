SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_email_order_confirmation_sp 2818839, 0, '035192', '', 'ocastaneda@cvoptical.com'

CREATE PROC [dbo].[cvo_email_order_confirmation_sp] @order_no int,
												@order_ext int,
												@customer_code varchar(10),
												@ship_to varchar(10),
												@email_address varchar(255)
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@subject_line	varchar(255),
			@body_text		varchar(max),
			@rc				int,
			@sch_ship_date	varchar(10)

	-- Processing
	-- If email has been sent do not send again
	IF EXISTS (SELECT 1 FROM cvo_email_order_sent (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		RETURN

	-- Check email address passed in from the order
	-- If no email specified then use the customer/ship to record contact email
	IF (@email_address IS NULL)
		SET @email_address = ''

	IF (@email_address = '' OR PATINDEX('%@%',@email_address) = 0)
	BEGIN
		IF (ISNULL(@ship_to,'') <> '')
		BEGIN
			SELECT	@email_address = contact_email
			FROM	armaster_all (NOLOCK)
			WHERE	customer_code = @customer_code
			AND		ship_to_code = @ship_to
			AND		address_type = 1
		END
		ELSE
		BEGIN
			SELECT	@email_address = contact_email
			FROM	armaster_all (NOLOCK)
			WHERE	customer_code = @customer_code
			AND		address_type = 0
		END

		IF (@email_address IS NULL)
			SET @email_address = ''

		IF (@email_address = '' OR PATINDEX('%@%',@email_address) = 0)
		BEGIN
			RETURN
		END
	END

	-- Working table
	CREATE TABLE #email_details(
		line_no			int,
		part_no			varchar(30),
		part_desc		varchar(255),
		ordered			int)

	-- Get Data
	INSERT	#email_details
	SELECT	line_no, part_no, description, ordered
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	SELECT	@sch_ship_date = CONVERT(varchar(10), sch_ship_date, 101)
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	-- Set email subject and body text
       SET @subject_line = 'Your ClearVision Order Confirmation - ' + CAST(@order_no AS varchar(20)) + '.'

	   SET @body_text = '<img src="https://s3.amazonaws.com/cvo-email-media/logo.png" alt="ClearVision Optical Company"><BR><BR>'
--    
       SET @body_text = @body_Text + '<font face = "verdana"> <h2 style="color:#025a89">Good News!</h2>'
       SET @body_text = @body_text + 'We have received your order and are processing it now. We will let you know as soon as it ships. <BR><BR>'
       SET @body_text = @body_text + '<H3>Order No: ' + CAST(@order_no as varchar(20))
              + '</H3><table width="100%" style="border:0;"><tr><td><table cellpadding="5" align="left" width="55%" style="border:0;">' +
              '<tr style="background:#025a89; color:#ffffff;" text-align="left"><th>Line</th><th>Part #</th>' +
              '<th>Description</th><th>Order Qty</th></tr>' +
              CAST(( SELECT td = line_no,       '',
                                  td = part_no, '',
                                  td = part_desc, '',
                                  td = ordered, ''
                           FROM #email_details
              ORDER BY line_no ASC
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    '</td></tr></table></table><BR><BR>' ;
 
       SET @body_text = @body_text + '<BR><BR><div style="clear:both; width:100%;"> Your estimated shipment date is  ' + @sch_ship_date + '.<BR><BR>' 
       SET @body_text = @body_text + 'Thank you for ordering from CVO!<BR><BR>' 
       SET @body_text = @body_text + 'ClearVision Optical Company<BR>'
       SET @body_text = @body_text + '425 Rabro Drive, Suite 2<BR>'
       SET @body_text = @body_text + 'Hauppauge, NY 11788<BR>'
       SET @body_text = @body_text + '1.800.645.3733 WWW.CVOPTICAL.COM<BR></div></font>'



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
					 @body_format = 'HTML',
					 @profile_name = 'OrderConfirmations'
		END
		ELSE
		BEGIN
			-- Call SQL email routine
			EXEC @rc = msdb.dbo.sp_send_dbmail
					 @recipients = @email_address,
					 @blind_copy_recipients = 'co@cvoptical.com',
					 @body = @body_text, 
					 @subject = @subject_line,
					 @body_format = 'HTML',
					 @profile_name = 'OrderConfirmations'
		END
	END

	-- Record email sent
	IF NOT EXISTS (SELECT 1 FROM cvo_email_order_sent (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
	BEGIN
		INSERT	cvo_email_order_sent (order_no, order_ext, email_address, sent_date)
		VALUES (@order_no, @order_ext, @email_address, GETDATE())	
	END

END








GO
GRANT EXECUTE ON  [dbo].[cvo_email_order_confirmation_sp] TO [public]
GO
