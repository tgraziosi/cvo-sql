SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 18/10/2012 - Process record in the CVO_auto_receive_credit_return table
-- v1.1 CB 28/07/2015 - Add another step for writing tdc log only when stock actually received (credit return posting)
-- make sure apply date is current 5/17/2017
/*
Processed values:
0 = New record, not processed
1 = Order on user hold
2 = Processed
3 = Received -- v1.1
-1 = Marked for processing
-2 = being processed

select ar.status_type, * From cvo_auto_receive_credit_return r
join orders o on o.order_no = r.order_no and o.ext = r.ext
join arcust ar on ar.customer_code = o.cust_code 
 where processed < 2

 943309

*/
CREATE PROC [dbo].[CVO_process_auto_receive_credit_return_sp]
AS
BEGIN
	DECLARE @rec_id		INT,
			@order_no	INT,
			@ext		INT,
			@processed	INT

	-- Delete any records processed in the previous run
	DELETE FROM
		dbo.CVO_auto_receive_credit_return
	WHERE 
		processed = 3 -- v1.1 2
	
	-- Update all records to show they are being processed
	UPDATE 
		dbo.CVO_auto_receive_credit_return
	SET
		processed = -1
	WHERE 
		processed IN (1,0,-1,-2)

	-- Loop through records and process them
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext
		FROM
			dbo.CVO_auto_receive_credit_return (NOLOCK)
		WHERE
			rec_id > @rec_id
			AND processed = -1
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Check credit isn't on user hold
		IF NOT EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND [status] = 'A')
		   AND EXISTS (SELECT 1 FROM orders_all (NOLOCK) o JOIN armaster ar ON ar.customer_code = o.cust_code AND ar.ship_to_code = o.ship_to
					WHERE ar.status_type=1 AND o.order_no = @order_no AND o.ext = @ext)
		   AND EXISTS (SELECT 1 FROM orders_all (NOLOCK) o JOIN dbo.cc_cust_status_hist AS ccsh ON ccsh.customer_code = o.cust_code
				    WHERE ISNULL(ccsh.status_code,'') = '' AND ccsh.clear_date IS NULL
					AND o.order_no = @order_no AND o.ext = @ext)
		BEGIN
			EXEC dbo.CVO_auto_receive_credit_return_sp @order_no, @ext
			SET @processed = 2
		END
		ELSE
		BEGIN
			SET @processed = 1 
		END
		-- Update record to show that it is processed
		UPDATE
			dbo.CVO_auto_receive_credit_return
		SET
			processed = @processed,
			processed_date = GETDATE()
		WHERE
			rec_id = @rec_id
		-- make sure apply date is current 5/17/2017
		UPDATE orders SET date_shipped = GETDATE() WHERE order_no = @order_no AND ext = @ext

	END

END



GO
