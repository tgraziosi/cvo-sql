SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*  
SED009 -- Transfer Orders - Product Shipping to & From a Sales Rep  
Object:      Procedure  CVO_send_xfer_notification_sp    
Source file: CVO_send_xfer_notification_sp.sql  
Author:   Jesus Velazquez  
Created:  09/21/2010  
Called by:   CVO_atm_xfer_receipts_sp, WMS Console (xfer receipts screen),   
Copyright:   Epicor Software 2010.  All rights reserved.
Example:	EXEC CVO_send_xfer_notification_sp 1650, 1
   
*/  
  
CREATE PROCEDURE [dbo].[CVO_send_xfer_notification_sp]	@order_no INT,  
														@action  INT  
AS  
  
BEGIN  
-- v3.1 CB 07/08/2013 - Issue #1202 - Add clippership tracking numbers
-- v3.2 CT 26/09/2013 - Issue #1202 - Send for all locations, only send for transfers with freight > 0, remove line items listing
-- v3.3 CT 02/10/2013 - Issue #1202 - Get freight value from tdc_carton_tx

--@action = 1 CVO to Sales Rep -- item are being shipped to them  
--@action = 2 Sales Rep to CVO -- transfer is created and saved  
--@action = 3 Sales Rep to CVO -- receipt was completed  
  
	DECLARE @from_loc	VARCHAR(10),  
			@to_loc		VARCHAR(10),  
			@main_loc	VARCHAR(10),  
			@attention	VARCHAR(15)  
  
	DECLARE @qty		VARCHAR(12),  
			@part_no	VARCHAR(30),  
			@collection VARCHAR(10),  
			@model		VARCHAR(40),  
			@color		VARCHAR(40),  
			@size		VARCHAR(12)  
  
	DECLARE @CVO_SALES_REP_email	VARCHAR(40),  
			@cvo_sales_rep_name		varchar(40),  
			@SUBJECT				VARCHAR(255),  
			@MESSAGE				VARCHAR(8000),
			@cs_tracking_number		varchar(255), -- v3.1     
			@freight				DECIMAL(20,8) -- v3.2
  
	--v3.0 Email no longer needed  
	-- v3.1 RETURN  

	SELECT	@from_loc = from_loc, 
			@to_loc = to_loc
			-- START v3.3 - remove
			--,@freight = freight -- v3.2  
			-- END v3.3
	FROM    xfers (nolock) 
	WHERE   xfer_no = @order_no  
   
	SET @main_loc = '001'  
  
	-- Option 2 will not be used at this time  
	IF @action = 2  
		RETURN  
  
/*  
sp_send_dbmail [ [ @profile_name = ] 'profile_name' ]  
    [ , [ @recipients = ] 'recipients [ ; ...n ]' ]  
    [ , [ @copy_recipients = ] 'copy_recipient [ ; ...n ]' ]  
    [ , [ @blind_copy_recipients = ] 'blind_copy_recipient [ ; ...n ]' ]  
    [ , [ @subject = ] 'subject' ]   
    [ , [ @body = ] 'body' ]   
    [ , [ @body_format = ] 'body_format' ]  
    [ , [ @importance = ] 'importance' ]  
    [ , [ @sensitivity = ] 'sensitivity' ]  
    [ , [ @file_attachments = ] 'attachment [ ; ...n ]' ]  
    [ , [ @query = ] 'query' ]  
    [ , [ @execute_query_database = ] 'execute_query_database' ]  
    [ , [ @attach_query_result_as_file = ] attach_query_result_as_file ]  
    [ , [ @query_attachment_filename = ] query_attachment_filename ]  
    [ , [ @query_result_header = ] query_result_header ]  
    [ , [ @query_result_width = ] query_result_width ]  
    [ , [ @query_result_separator = ] 'query_result_separator' ]  
    [ , [ @exclude_query_output = ] exclude_query_output ]  
    [ , [ @append_query_error = ] append_query_error ]  
    [ , [ @query_no_truncate = ] query_no_truncate ]  
    [ , [ @mailitem_id = ] mailitem_id ] [ OUTPUT ]  
*/  
  
	-- START v3.2 - email for all locations
	IF @action = 1
	--IF @action = 1 AND @from_loc = @main_loc  
	-- END v3.2
	BEGIN  
		-- START v3.3
		SELECT 
			@freight = MAX(ISNULL(cs_published_freight,0)) 
		FROM 
			dbo.tdc_carton_tx (NOLOCK) 
		WHERE 
			order_type = 'T' 
			AND order_no = @order_no
		-- END v3.3

		-- START v3.2 - only send email for transfers with freight > 0
		IF ISNULL(@freight,0) <= 0
		BEGIN
			RETURN
		END
		-- END v3.2

		SET @SUBJECT = 'Samples Shipped'  
		SET @MESSAGE = ''  
  
		SELECT	@CVO_SALES_REP_email = addr5, 
				@cvo_sales_rep_name = name 
		FROM	locations (NOLOCK) 
		WHERE	location = @to_loc  
  
		SELECT	@attention = IsNull(attention,'Following') 
		FROM	xfers 
		WHERE	xfer_no = @order_no  
    
		IF (@CVO_SALES_REP_email IS NOT NULL) AND (@CVO_SALES_REP_email != '')  
		BEGIN  
			SELECT @MESSAGE = 'Dear ' + @cvo_sales_rep_name + ': <BR><BR>'  
			SELECT @MESSAGE = @MESSAGE + 'Please be advised that the ' + @attention + ' has been ' 
			
			-- START v3.2 - change email format 
			--SELECT @MESSAGE = @MESSAGE + 'processed and shipped to your address.  This release contains the following items: <BR><BR> '  
			SELECT @MESSAGE = @MESSAGE + 'processed and shipped to your address. <BR> '  
  
			/*
			DECLARE oline CURSOR FOR  
			SELECT	x.part_no, 
					convert(varchar(15),
					convert(int,x.ordered)), 
					i1.category, 
					i2.field_2, 
					i2.field_3,   
					IsNull(convert(varchar(15),convert(int,i2.field_17)) + '/' + i2.field_6 + '/' + i2.field_8,' ') as size   
			FROM	xfer_list x (NOLOCK)
			INNER JOIN inv_master i1 (NOLOCK) 
			ON		x.part_no = i1.part_no  
			INNER JOIN inv_master_add i2 (NOLOCK) 
			ON		x.part_no = i2.part_no  
			WHERE	xfer_no = @order_no  
   
			OPEN oline  
			FETCH NEXT FROM oline INTO @part_no, @qty, @collection, @model, @color, @size  
			WHILE @@FETCH_STATUS = 0  
			BEGIN  
			
				SELECT @MESSAGE = @MESSAGE + '<B>SKU: </B>' + ISNULL(@part_no,'') + '<B>&nbsp;Qty: </B>' + ISNULL(@qty, 0) + '<B>&nbsp;Collection: </B>' + ISNULL(@collection,'')  
				SELECT @MESSAGE = @MESSAGE + '<B>&nbsp;Model: </B>' + ISNULL(@model,'') + '<B>&nbsp;Color: </B>' + ISNULL(@color,'') + '<B>&nbsp;Size: </B> ' + @size + '<BR>'  
  
				FETCH NEXT FROM oline INTO @part_no, @qty, @collection, @model, @color, @size  
			END  
			CLOSE oline  
			DEALLOCATE oline 
			*/
			-- END v3.2

			-- v3.1 Start
			SELECT @MESSAGE = @MESSAGE + '<BR>Tracking Number(s):<BR>'

			DECLARE	tracking_cursor CURSOR FOR
			SELECT	cs_tracking_no FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_type = 'T' AND ISNULL(cs_tracking_no,'') > ''

			OPEN tracking_cursor

			FETCH NEXT FROM tracking_cursor INTO @cs_tracking_number

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				
				SELECT @MESSAGE = @MESSAGE + @cs_tracking_number + '<BR>'

				FETCH NEXT FROM tracking_cursor INTO @cs_tracking_number
			END

			CLOSE tracking_cursor
			DEALLOCATE tracking_cursor
			-- v3.1 End

			SELECT @MESSAGE = @MESSAGE + '<BR>Please Contact Sales Support if you have any questions. <BR><BR>'  
			SELECT @MESSAGE = @MESSAGE + '<I>This is an automated e-mail, please do not respond. </I> '  
 
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'WMS_1',  
										@recipients  = @CVO_SALES_REP_email,   
										@subject  = @SUBJECT,   
										@body   = @MESSAGE,  
										@body_format = 'HTML',  
										@importance  = 'HIGH';  
  
			INSERT INTO tdc_log (tran_date,    userID, trans_source, module,         trans,   tran_no,  data)  
			VALUES (getdate(), 'manager',         'VB',  'PPS', 'ShipConfirm', @order_no,  'mail to: ' + @CVO_SALES_REP_email )  
		END          
	END  
  
	/*  -- NOT CURRENTLY USED  
	IF @action = 2 AND @to_loc = @main_loc  
	BEGIN  
		SET @SUBJECT = ''  
		SET @MESSAGE = ''  
  
		SELECT @CVO_SALES_REP_email = addr5, @cvo_sales_rep_name = name FROM locations WHERE location = @to_loc  
  
		IF (@CVO_SALES_REP_email IS NOT NULL) AND (@CVO_SALES_REP_email != '')  
		BEGIN  
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'WMS_1',  
										@recipients  = @CVO_SALES_REP_email,   
										@subject  = @SUBJECT,   
										@body   = @MESSAGE,  
										@body_format = 'HTML',  
										@importance  = 'HIGH';  
  
			INSERT INTO tdc_log (tran_date,    userID, trans_source, module,         trans,   tran_no,  data)  
			VALUES              (getdate(), 'manager',         'VB',  'PPS', 'ShipConfirm', @order_no,  'mail to: ' + @CVO_SALES_REP_email )  
            
		END          
	END  
	*/  
  
	IF @action = 3 AND @to_loc = @main_loc  
	BEGIN  
		SET @SUBJECT = 'Samples Received at CVO'  
		SET @MESSAGE = ''  
  
		SELECT @CVO_SALES_REP_email = addr5, @cvo_sales_rep_name = name FROM locations WHERE location = @from_loc  
		SELECT @attention = IsNull(attention,'Following') FROM xfers WHERE xfer_no = @order_no  
   
		IF (@CVO_SALES_REP_email IS NOT NULL) AND (@CVO_SALES_REP_email != '')  
		BEGIN  
			SELECT @MESSAGE = 'Dear ' + @cvo_sales_rep_name + ': <BR><BR>'  
			SELECT @MESSAGE = @MESSAGE + 'Please be advised that the ' + @attention + ' has been '  
			SELECT @MESSAGE = @MESSAGE + 'received and processed.  Your accepted return contained the following items: <BR><BR> '  
  
			DECLARE oline CURSOR FOR  
			SELECT	x.part_no, 
					convert(varchar(15),
					convert(int,x.ordered)), 
					i1.category, 
					i2.field_2, 
					i2.field_3,   
					IsNull(convert(varchar(15),convert(int,i2.field_17))+'/'+i2.field_6+'/'+i2.field_8,' ') as size   
			FROM xfer_list x  
			inner join inv_master i1 on x.part_no = i1.part_no  
			inner join inv_master_add i2 on x.part_no = i2.part_no  
			WHERE xfer_no = @order_no  
   
			OPEN oline  
			FETCH NEXT FROM oline INTO @part_no, @qty, @collection, @model, @color, @size  
			WHILE @@FETCH_STATUS = 0  
			BEGIN  
				SELECT @MESSAGE = @MESSAGE + '<B>SKU: </B>'+@part_no+'    <B>Qty: </B>'+@qty+'    <B>Collection: </B>'+@collection  
				SELECT @MESSAGE = @MESSAGE + '    <B>Model: </B>'+@model+'    <B>Color: </B>'+@color+'    <B>Size: </B>'+@size+'<BR>'  
  
				FETCH NEXT FROM oline INTO @part_no, @qty, @collection, @model, @color, @size  
			END  
			CLOSE oline  
			DEALLOCATE oline  
  
			SELECT @MESSAGE = @MESSAGE + '<BR>If any items are missing from this recall or have been returned damaged, '  
			SELECT @MESSAGE = @MESSAGE + 'you may be invoiced seperately for them. <BR><BR>'  
			SELECT @MESSAGE = @MESSAGE + '<I>This is an automated e-mail, please do not respond. </I> '  
  
			--select @CVO_SALES_REP_email = 'tmcgrady@epicor.com'   -- For Testing Only  
  
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'WMS_1',  
										@recipients  = @CVO_SALES_REP_email,   
										@subject  = @SUBJECT,   
										@body   = @MESSAGE,  
										@body_format = 'HTML',  
										@importance  = 'HIGH';  
  
			INSERT INTO tdc_log (tran_date,    userID, trans_source, module,         trans,   tran_no,  data)  
			VALUES              (getdate(), 'manager',         'VB',  'PPS', 'Received', @order_no,  'mail to: ' + @CVO_SALES_REP_email )  
            
		END          
	END  
 
END  

GO
GRANT EXECUTE ON  [dbo].[CVO_send_xfer_notification_sp] TO [public]
GO
