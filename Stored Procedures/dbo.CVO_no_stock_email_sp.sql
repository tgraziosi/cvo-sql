SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC CVO_no_stock_email_sp @order_no = 1419847, @order_ext = 0, @line_no = 5, @type = 3
-- 7/7/2014 - TAG - Show display line in email instead of line_no


CREATE PROCEDURE [dbo].[CVO_no_stock_email_sp]	@order_no int,
											@order_ext int,
											@new_order_no int = 0,
											@line_no int = 0,
											@type int = 0  -- 0=hard allocation no stock, 1=allow BO pick, 2=ship complete pick, 3=allow partial
AS

BEGIN

	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@who_entered		varchar(50),
			@user_email			varchar(255),
			@cust_code			varchar(10),
			@ship_to_name		varchar(60),
			@subject			varchar(255),
			@message			varchar(8000),
			@part_no			varchar(30),
			@qty				decimal(20,8)
			, @display_line		int	-- 7/7/2014 - TAG

	-- Get the user who entered the order
	SELECT	@who_entered = who_entered,
			@cust_code = cust_code,
			@ship_to_name = ship_to_name
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	-- Does the user exist in the CVO_user_email
	IF NOT EXISTS (SELECT 1 FROM CVO_user_email (NOLOCK) WHERE userid = @who_entered)
		RETURN

	SELECT	@user_email = email_address
	FROM	CVO_user_email (NOLOCK)
	WHERE	userid = @who_entered

	IF 	ISNULL(@user_email,'') = ''
		RETURN	

	IF (@new_order_no <> 0)
	BEGIN

		SELECT	@part_no = part_no,
				@qty = ordered
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no = @line_no

		SET @subject = 'Order: ' + CAST(@order_no AS varchar(20)) + ' - Missing Stock'

		SET @message = 'The following order has been flagged with missing stock. <BR><BR>'
		SET @message = @message + '<B>Order#: ' + CAST(@order_no AS varchar(20)) + '</B>'
		SET @message = @message + '<BR>Customer: ' + @cust_code + ' / ' + @ship_to_name + ' '
		SET @message = @message + '<BR>Part: ' + @part_no + ' '
		SET @message = @message + '<BR>Qty: ' + CAST((CAST(@qty as int)) as varchar(20)) + ' <BR><BR>'
		IF @new_order_no <> -1
			SET @message = @message + '<BR>The original order has been voided, new order: ' + CAST(@new_order_no as varchar(20)) + ' <BR><BR><BR>'
		SET @message = @message + '<BR><I>Automated e-mail generated from Epicor.  Please do not respond. </I> '
	END
	ELSE
	BEGIN
		-- START v1.1
		IF ISNULL(@line_no,0) <> 0
		BEGIN
			SELECT	@part_no = part_no,
					@display_line = display_line -- 7/7/2014 - TAG
			FROM	ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
		END
		
		SET @subject = 'Order: ' + CAST(@order_no AS varchar(20)) + ' - No Stock Notification'

		-- Hard allocation no stock
		IF @type = 0
		BEGIN
			SET @message = 'The following order has been placed on Hold due to no stock being available. <BR><BR>'
		END

		-- Allow BO pick
		IF @type = 1
		BEGIN
			SET @message = 'The following order has a line item that has been backordered due to a no stock. <BR><BR>'
		END

		-- Ship Complete pick
		IF @type = 2
		BEGIN
			SET @message = 'The following ship complete order will be held due to an unavailable line item (no stock). <BR><BR>'
		END
		
		-- START v1.2
		-- Allow BO pick
		IF @type = 3
		BEGIN
			SET @message = 'The following order has a line item that is not available. This order is set to Allow Partial – a backorder will not be created. <BR><BR>'
		END
		-- END v1.2

		SET @message = @message + '<B>Order#: ' + CAST(@order_no AS varchar(20)) + '</B>'
		SET @message = @message + '<BR>Customer: ' + @cust_code + ' / ' + @ship_to_name 
		IF ISNULL(@line_no,0) <> 0
		BEGIN
-- 7/7/2014 TAG		SET @message = @message + '<BR>Line item: ' + CAST(@line_no AS VARCHAR(4)) + ' - Part no.: ' + @part_no + ' '
			SET @message = @message + '<BR>Line item: ' + CAST(@display_line AS VARCHAR(4)) + ' - Part no.: ' + @part_no + ' '
		END
		SET @message = @message + ' <BR><BR><BR>'
		SET @message = @message + '<BR><I>Automated e-mail generated from Epicor.  Please do not respond. </I> '



		-- Original email code
		/*
		SET @subject = 'Order: ' + CAST(@order_no AS varchar(20)) + ' - No Stock Notification'
	  
		SET @message = 'The following order has been placed on Hold due to no stock being available. <BR><BR>'
		SET @message = @message + '<B>Order#: ' + CAST(@order_no AS varchar(20)) + '</B>'
		SET @message = @message + '<BR>Customer: ' + @cust_code + ' / ' + @ship_to_name + ' <BR><BR><BR>'
		SET @message = @message + '<BR><I>Automated e-mail generated from Epicor.  Please do not respond. </I> '
		*/

		-- END v1.1	
		

	END

	/*
	-- Testing HTML output
	SELECT @message
	RETURN
	*/

	IF (PATINDEX('%epicor%',@user_email) > 0)
	BEGIN
		INSERT	epicor_email_results (email_address, email_subject, email_message)
		SELECT	@user_email, @subject, @message
		RETURN	
	END

	EXEC msdb.dbo.sp_send_dbmail	@profile_name	= 'WMS_1',
									@recipients		= @user_email,
	--								@copy_recipients = 'nfagan@cvoptical.com', -- 040714 
									@subject		= @subject, 
									@body			= @message,
									@body_format	= 'HTML',
									@importance		= 'HIGH';

END

GO
GRANT EXECUTE ON  [dbo].[CVO_no_stock_email_sp] TO [public]
GO
