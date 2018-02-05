SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_email_cc_confirmation_sp] @customer_code varchar(8),
											 @str_amount varchar(50),
											 @nat_cur_code varchar(8)
AS
BEGIN

	-- 2/2/2018 - stop sending to co@cvoptical.com
	-- EXEC dbo.cvo_email_cc_confirmation_sp '011111', '1.00','USD'
	
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@email_address	varchar(255),
			@subject_line	varchar(255),
			@body_text		varchar(5000),
			@rc				int,
			@cur_symbol		varchar(8),
			@customer_name  VARCHAR(255)
	
	-- Processing
	SET @email_address = ''
	SELECT	@email_address = ISNULL(attention_email,''),
			@customer_name = ISNULL(customer_name,'')
	FROM	arcust (NOLOCK)
	WHERE	customer_code = @customer_code

	IF (@email_address = '' OR PATINDEX('%@%',@email_address) = 0)
		-- SET @email_address = 'co@cvoptical.com'
		RETURN

	SELECT	@cur_symbol = symbol
	FROM	dbo.mccu1_vw (NOLOCK)
	WHERE	currency_code = @nat_cur_code

	IF (@cur_symbol IS NULL)
		SET @cur_symbol = ''
	ELSE
		SET @cur_symbol = RTRIM(@cur_symbol) + ' '

	SET @str_amount = @cur_symbol + @str_amount

	-- Set email subject and body text
	SET @subject_line = 'Your ClearVision Credit Card Payment Confirmation (' + @customer_code + ')'

	SET @body_text = ''
	SET @body_text = @body_text + '<img src="https://s3.amazonaws.com/cvo-email-media/logo.png" alt="ClearVision Optical Company"><BR><BR>'
		
	SET @body_text = @body_text + '<font face = "verdana"> <h2 style="color:#025a89">Hello ' + @customer_name + '!</h2> <BR><BR>'
	SET @body_text = @body_text + 'Your credit card has been charged ' + @str_amount + ' <BR><BR>'
	SET @body_text = @body_text + 'Thank you for your payment.<BR><BR>'	
	SET @body_text = @body_text + 'If you have any questions, please feel free to contact our Customer Care department at 800.645.3733 <BR><BR>'
	SET @body_text = @body_text + 'ClearVision Optical Company<BR>'
	SET @body_text = @body_text + '425 Rabro Drive, Suite 2<BR>'
	SET @body_text = @body_text + 'Hauppauge, NY 11788<BR>'
	SET @body_text = @body_text + '1.800.645.3733 WWW.CVOPTICAL.COM<BR> </font>'

	IF (@@servername <> 'cvo-db-03') -- for testing
	BEGIN
		--SET @email_address = 'cboston@epicor.com'
		SET @email_address = 'tgraziosi@cvoptical.com'
		SET @subject_line = @subject_line + ' - TESTING'

		EXEC @rc = msdb.dbo.sp_send_dbmail
				 @recipients = @email_address,
				 --@blind_copy_recipients = 'co@cvoptical.com',
				 @body = @body_text, 
				 @subject = @subject_line,
				 @body_format = 'HTML',
				 @profile_name = 'OrderConfirmations'
	END
	ELSE
	BEGIN
	-- temporary - for testing only
		SET @email_address = 'co@cvoptical.com'
		-- Call SQL email routine
		EXEC @rc = msdb.dbo.sp_send_dbmail
				 @recipients = @email_address,
				 -- @blind_copy_recipients = 'co@cvoptical.com',
				 @body = @body_text, 
				 @subject = @subject_line,
				 @body_format = 'HTML',
				 @profile_name = 'OrderConfirmations'
	END

END


GO
GRANT EXECUTE ON  [dbo].[cvo_email_cc_confirmation_sp] TO [public]
GO
