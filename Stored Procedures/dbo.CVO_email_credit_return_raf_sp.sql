SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC CVO_email_credit_return_raf_sp
-- v1.1 TG - CC the sales rep and send to rma@cvoptical.com

/*
Sent values:
0 = unprocessed
1 = processed
-1 = marked for processing
-2 = error sending email
-3 = credit return void or not on hold any longer -- tag -  11/25/2014
*/


CREATE PROC [dbo].[CVO_email_credit_return_raf_sp]
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@rec_id			INT,
			@email_address	VARCHAR(255),
			@subject_line	VARCHAR(255),
			@body_text		VARCHAR(5000),
			@attachment		VARCHAR(500),
			@rc				INT, 
			@mailitem_id	INT,
			@order_no		INT,
			@ext			INT

	declare @slp_email varchar(255), @cust_code varchar(10), @ship_to varchar(10), @ship_to_name varchar(40)
	
	-- Process each record in the queue
	UPDATE	
		dbo.CVO_email_credit_return_raf
	SET		
		sent = -1
	WHERE	
		sent IN (0,-1)

	-- Set email subject and body text
	-- SET @subject_line = 'Your Return Label is Ready To Print!'
	SET @body_text = 'Hello! <BR><BR>'
	SET @body_text = @body_text + 'Your sales consultant has sent us your return request. Attached please find your return authorization form. <BR>'
	set @body_text = @body_text + 'Adobe Reader software is required to open this attachment.  If you don’t have it, please download it free at http://get.adobe.com/reader/ <BR><BR>'
	SET @body_text = @body_text + 'To complete the return process:<BR>'
	SET @body_text = @body_text + '&bull; Print the attached RMA form and include in your shipment.<BR>'
	SET @body_text = @body_text + '&bull; Review the RMA form and confirm the frames you are shipping match those listed. If there are any discrepancies, please mark the form appropriately.<BR>'
	SET @body_text = @body_text + '&bull; Please use the included shipping label.<BR>'
	SET @body_text = @body_text + '&bull; Please package your return carefully to protect the contents; all frames should be individually wrapped, preferably in poly bags.<BR><BR>'
	SET @body_text = @body_text + 'Once your return is received and inspected (usually within 72 hours of receipt), we will process your return and automatically apply a credit to your account.<BR><BR>'
	SET @body_text = @body_text + 'Thank you for being a part of the CVO family!<BR><BR>'
	SET @body_text = @body_text + '<i>ClearVision Optical Customer Care</i><BR>'
	SET @body_text = @body_text + '<i>1.800.645.3733</i><BR>'
	SET @body_text = @body_text + '<i>425 Rabro Drive, Suite 2</i><BR>'
	SET @body_text = @body_text + '<i>Hauppauge, NY 11788</i><BR>'

	SET	@rec_id = 0

	WHILE 1=1
	BEGIN

		SELECT	TOP 1 
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@email_address = contact_email,
			@attachment = attachment
		FROM	
			dbo.CVO_email_credit_return_raf (NOLOCK) 
		WHERE	
			sent = -1
			AND	rec_id > @rec_id
			and contact_email is not null -- 12/12/2014 -- tag
		ORDER BY 
			rec_id ASC

		IF @@ROWCOUNT = 0
			BREAK

		-- get the sales reps email address
		if (@@servername <> 'cvo-db-03') -- for testing
		begin
			set @email_address = 'tgraziosi@cvoptical.com'
		end
		select top 1 @slp_email = isnull(sc.slp_email,''), 
					 @cust_code = isnull(o.cust_code,''), 
					 @ship_to = isnull(o.ship_to,''),
					 @ship_to_name = isnull(o.ship_to_name,'') 
			from cvo_sc_addr_vw sc
			join dbo.orders o (nolock) on sc.salesperson_code = o.salesperson
			where o.order_no = @order_no and ext = @ext
		
			set @subject_line = 'Your Return Label is Ready To Print! - [' + @cust_code+'-'+@ship_to+' '+ltrim(rtrim(@ship_to_name))+']'

		-- If credit return is void or Not on Hold anymore then don't send, instead set set to -3
		IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @ext and [status] <> 'A' )
		-- and [status] ='V')
		BEGIN
			UPDATE	
				dbo.CVO_email_credit_return_raf
			SET		
				sent = -3
			WHERE	
				rec_id = @rec_id
		END

		ELSE
		BEGIN
			-- If running in Poole office, don't send email
			IF (SELECT @@SERVERNAME) IN ('CUSTSQL\BLANCO','V227230K')
			BEGIN
				SET @rc = 0
			END
			ELSE
			BEGIN
				if @@servername <> 'cvo-db-03'
				begin
					set @subject_line = @slp_email+' '+@subject_line
					set @slp_email = ''
					set @email_address = 'tgraziosi@cvoptical.com'
				end
				-- Call SQL email routine
				EXEC @rc = msdb.dbo.sp_send_dbmail
					 @recipients = @email_address,
					 @body = @body_text, 
					 @subject = @subject_line,
					 @profile_name = 'OrderConfirmations',
					 @file_attachments = @attachment,
					 @mailitem_id = @mailitem_id OUTPUT,
					 @body_format = 'HTML' -- tag
					 , @blind_copy_recipients = 'rma@cvoptical.com' -- tag 06/20/2014
					 , @copy_recipients = @slp_email 
				END

			IF @rc <> 0
			BEGIN
				UPDATE	
					dbo.CVO_email_credit_return_raf
				SET		
					sent = -2
				WHERE	
					rec_id = @rec_id
			END
			ELSE
			BEGIN
				UPDATE	
					dbo.CVO_email_credit_return_raf
				SET		
					sent = 1,
					date_sent = GETDATE()
				WHERE	
					rec_id = @rec_id
			END
		END
	END

END
GO
GRANT EXECUTE ON  [dbo].[CVO_email_credit_return_raf_sp] TO [public]
GO
