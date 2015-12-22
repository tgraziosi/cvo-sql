SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC CVO_autopack_carton_pick_sp @order_no =, @order_ext = , @line_no = , @part_no = , @qty = 

CREATE PROC [dbo].[CVO_autopack_carton_pick_sp] (	@order_no	INT,
												@order_ext	INT,
												@line_no	INT,
												@part_no	VARCHAR(30),
												@qty		DECIMAL (20,8))
AS
BEGIN
	DECLARE @autopack_id	INT,
			@unpicked_qty	DECIMAL(20,8),
			@remaining_qty	DECIMAL(20,8),
			@qty_to_apply	INT
		


	-- Check this is a valid stock order
	IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND [type] = 'I' AND LEFT(user_category,2) = 'ST' AND location < '100')	
	BEGIN
		RETURN
	END

	SET @remaining_qty = @qty
	SET @autopack_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@autopack_id = autopack_id,
			@unpicked_qty = qty - ISNULL(picked,0)
		FROM
			dbo.CVO_autopack_carton (NOLOCK) 
		WHERE 
			order_no = @order_no 
			AND order_ext = @order_ext
			AND line_no = @line_no
			AND qty - ISNULL(picked,0) > 0
			AND autopack_id > @autopack_id
		ORDER BY
			autopack_id
	
		IF @@ROWCOUNT = 0
			BREAK

		IF @unpicked_qty >= @remaining_qty
		BEGIN
			SET @qty_to_apply = @remaining_qty
			SET @remaining_qty = 0
		END
		ELSE
		BEGIN
			SET @qty_to_apply = @unpicked_qty
			SET @remaining_qty = @remaining_qty - @unpicked_qty
		END

		-- update picked qty
		UPDATE
			dbo.CVO_autopack_carton
		SET
			picked = picked + @qty_to_apply
		WHERE
			autopack_id = @autopack_id

		IF @remaining_qty = 0
			BREAK
	END
		
END

GO
GRANT EXECUTE ON  [dbo].[CVO_autopack_carton_pick_sp] TO [public]
GO
