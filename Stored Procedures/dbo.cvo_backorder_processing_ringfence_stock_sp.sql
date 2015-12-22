SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
v1.1 CT 28/11/2013 - Issue #1406 - no longer ringfencing stock, set to_bin_no = the current bin 

*/

CREATE PROC [dbo].[cvo_backorder_processing_ringfence_stock_sp]    (@order_no		INT,
																@ext			INT,
																@line_no		INT,	
																@part_no		VARCHAR(30),
																@location		VARCHAR(10),
																@qty			DECIMAL(20,8),
																@to_bin_no		VARCHAR(12),
																@template_code	VARCHAR(30))

AS
BEGIN
	DECLARE @bin_rec_id	INT,
			@to_process	DECIMAL(20,8),
			@bin_no		VARCHAR(12),
			@bin_qty	DECIMAL(20,8),
			@ringfenced	DECIMAL(20,8),
			@user		VARCHAR(20)

	
	-- Get user ID
	SELECT 
		@user = ISNULL(changed_user,entered_user) 
	FROM 
		dbo.cvo_backorder_processing_templates 
	WHERE 
		template_code = @template_code


	-- Create temp table for bin selection
	CREATE TABLE #bins(
		rec_id		INT IDENTITY(1,1),
		location	VARCHAR(10),
		bin_no		VARCHAR(12),
		qty			DECIMAL(20,8))

	-- Get bins containing this part
	EXEC cvo_backorder_processing_bins_select_sp @part_no, @location, @qty		

	-- Loop through bins
	SET @bin_rec_id = 0
	SET @to_process = @qty

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@bin_rec_id = rec_id,
			@bin_no = bin_no,
			@bin_qty = qty
		FROM
			#bins
		WHERE
			rec_id > @bin_rec_id
		ORDER BY 
			rec_id

		IF @@ROWCOUNT = 0
		BREAK

		IF @to_process <= @bin_qty
		BEGIN
			SET @ringfenced = @to_process
			SET @to_process = 0
		END
		ELSE
		BEGIN
			SET @ringfenced = @bin_qty
			SET @to_process = @to_process - @bin_qty
		END

		-- START v1.1
		SET @to_bin_no = @bin_no
		-- END v1.1

		-- Bin to bin the stock
 		EXEC cvo_bin2bin_sp @part_no, @location, @bin_no, @to_bin_no, @ringfenced, @user

		-- Write tracking record
		INSERT INTO dbo.CVO_backorder_processing_orders_ringfenced_stock(
			template_code,
			order_no,
			ext,
			line_no,
			part_no,
			location,
			bin_no,
			orig_bin_no,
			qty_reqd,
			qty_ringfenced,
			qty_processed,
			[status])
		SELECT
			@template_code,
			@order_no,
			@ext,
			@line_no,
			@part_no,
			@location,
			@to_bin_no,
			@bin_no,
			@qty,
			@ringfenced,
			0,
			0

		IF @to_process = 0
			BREAK

	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_ringfence_stock_sp] TO [public]
GO
