SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*


*/

CREATE PROC [dbo].[cvo_backorder_processing_unringfence_stock_sp]  (@order_no		INT,
																@ext			INT,
																@line_no		INT,	
																@part_no		VARCHAR(30),
																@location		VARCHAR(10),
																@template_code	VARCHAR(30))

AS
BEGIN
	DECLARE @alloc_rec_id	INT,
			@bin_no			VARCHAR(12),
			@orig_bin_no	VARCHAR(12),
			@ringfenced		DECIMAL(20,8),
			@user			VARCHAR(20)

	
	-- Get user ID
	SELECT 
		@user = ISNULL(changed_user,entered_user) 
	FROM 
		dbo.cvo_backorder_processing_templates 
	WHERE 
		template_code = @template_code

	-- Loop through allocated records and release the stock
	SET @alloc_rec_id = 0
	WHILE 1=1
	BEGIN	

		SELECT TOP 1
			@alloc_rec_id = rec_id,
			@ringfenced = qty_ringfenced,
			@bin_no = bin_no,
			@orig_bin_no = orig_bin_no
		FROM
			dbo.CVO_backorder_processing_orders_ringfenced_stock (NOLOCK)
		WHERE
			template_code = @template_code
			AND order_no = @order_no
			AND ext = @ext
			AND line_no = @line_no
			AND rec_id > @alloc_rec_id
			AND [status] = 0
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Bin to Bin back to orginal bin
		EXEC cvo_bin2bin_sp @part_no, @location, @bin_no, @orig_bin_no, @ringfenced, @user

		-- Delete record
		DELETE dbo.CVO_backorder_processing_orders_ringfenced_stock WHERE rec_id = @alloc_rec_id
	
	END		

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_unringfence_stock_sp] TO [public]
GO
