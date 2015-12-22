SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_GetSubstitutedStock_sp]	@order_no	int,
											@order_ext	int
AS
BEGIN
	DECLARE @part_no		varchar(30),
			@location		varchar(10),
			@qty			decimal(20,8),
			@row_id			int,
			@last_row_id	int,
			@line_no		int,
			@qty_available	decimal(20,8)

	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_ord_list_kit (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND replaced = 'S')
	BEGIN
		SELECT 0
		RETURN
	END

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@part_no = part_no,
				@line_no = line_no
	FROM	dbo.cvo_ord_list_kit (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	AND		replaced = 'S'
	AND		row_id > @last_row_id
	ORDER BY row_id asc

	WHILE @@ROWCOUNT <> 0
	BEGIN	
	
		SELECT	@qty = ordered 
		FROM	dbo.ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no = @line_no

		EXEC @qty_available = dbo.CVO_CheckAvailabilityInStock_sp @part_no,@location, 0
		
		IF @qty > @qty_available
		BEGIN
			SELECT -1
			RETURN
		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
					@location = location,
					@part_no = part_no,
					@line_no = line_no
		FROM	dbo.cvo_ord_list_kit (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		replaced = 'S'
		AND		row_id > @last_row_id
		ORDER BY row_id asc

	END

	SELECT 0
END
GO
GRANT EXECUTE ON  [dbo].[CVO_GetSubstitutedStock_sp] TO [public]
GO
