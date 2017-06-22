SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC CVO_no_stock_admin_email_sp 1421860, 0, 'BIN1', 'PART1', 10

CREATE PROC [dbo].[CVO_no_stock_admin_email_sp]	@order_no int,
											@order_ext int,
											@bin_no varchar(20),
											@part_no varchar(30),
											@qty_removed decimal(20,8)

AS
BEGIN

	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@user_email			varchar(255),
			@cust_code			varchar(10),
			@ship_to_name		varchar(60),
			@subject			varchar(255),
			@message			varchar(8000)

	-- Get the user who entered the order
	SELECT	@cust_code = cust_code,
			@ship_to_name = ship_to_name
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	SELECT	@user_email = '#nostock@cvoptical.com'

	SET @subject = 'Order: ' + CAST(@order_no AS varchar(20)) + ' - Missing Stock'

	SET @message = 'The following order has been flagged with missing stock. <BR><BR>'
	SET @message = @message + '<B>Order#: ' + CAST(@order_no AS varchar(20)) + '</B>'
	SET @message = @message + '<BR>Customer: ' + @cust_code + ' / ' + @ship_to_name + ' '
	SET @message = @message + '<BR>Bin Number: ' + @bin_no + ' '
	SET @message = @message + '<BR>Part: ' + @part_no + ' '
	SET @message = @message + '<BR>Qty: ' + CAST((CAST(@qty_removed as int)) as varchar(20)) + ' <BR><BR>'
	SET @message = @message + '<BR>Please carry out a cycle or spot count on this bin. <BR><BR>'
	SET @message = @message + '<BR><I>Automated e-mail generated from Epicor.  Please do not respond. </I> '

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
									@subject		= @subject, 
									@body			= @message,
									@body_format	= 'HTML',
									@importance		= 'HIGH';

END
GO
GRANT EXECUTE ON  [dbo].[CVO_no_stock_admin_email_sp] TO [public]
GO
