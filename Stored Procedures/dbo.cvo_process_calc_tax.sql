SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_process_calc_tax]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @row_id			int,
			@last_row_id	int,
			@err_ret		int,
			@order_no		int,
			@order_ext		int

	-- Create Working Table
	CREATE TABLE #process_tax (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int)

	-- Insert records to process
	INSERT	#process_tax (order_no, order_ext)
	SELECT	order_no, order_ext
	FROM	dbo.cvo_calc_tax (NOLOCK)

	-- Process the records
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#process_tax
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
		
		EXEC dbo.CVO_GetFreight_recalculate_sp	@order_no, @order_ext, 2 -- v1.1
		EXEC dbo.fs_calculate_oetax @order_no, @order_ext, @err_ret OUT  
		EXEC dbo.fs_updordtots @order_no, @order_ext     

		DELETE dbo.cvo_calc_tax WHERE order_no = @order_no AND order_ext = @order_ext	

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#process_tax
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END	

	-- Clean up
	DROP TABLE #process_tax

END 
GO
GRANT EXECUTE ON  [dbo].[cvo_process_calc_tax] TO [public]
GO
