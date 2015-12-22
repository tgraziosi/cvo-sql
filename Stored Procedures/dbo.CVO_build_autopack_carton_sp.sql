SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 16/08/2012 - Created
-- v1.1 CT 18/09/2012 - Check config to see if functionality is enabled
-- v1.2 CB 24/09/2012 - Modify to work with soft allocation
-- v1.3 CT 03/10/2012 - Load tdc_soft_alloc_tbl records into temporary table


CREATE PROC [dbo].[CVO_build_autopack_carton_sp] (	@order_no	INT,
												@order_ext	INT)
AS
BEGIN
	
	DECLARE @line_no		INT,
			@part_no		VARCHAR(30),
			@qty			DECIMAL(20,8),
			@unpicked		DECIMAL(20,8),
			@carton_id		INT,
			@carton_no		INT


	-- START v1.1
	IF NOT EXISTS (SELECT 1 FROM dbo.tdc_config WHERE [function] = 'AUTOPACK_STOCK_ORDERS' AND active = 'Y' AND value_str = 'Y')
	BEGIN
		RETURN
	END
	-- END v1.1

	-- Check order is a valid autopack order
	IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND [type] = 'I' AND LEFT(user_category,2) = 'ST' AND location < '100')
	BEGIN
		RETURN
	END

	-- v1.2 Start	

	IF (OBJECT_ID('tempdb..#cvo_ord_list') IS NOT NULL) 
		DROP TABLE #cvo_ord_list

	CREATE TABLE #cvo_ord_list(
		order_no int NOT NULL,
		order_ext int NOT NULL,
		line_no int NOT NULL,
		add_case varchar(1) NULL DEFAULT ('N'),
		add_pattern varchar(1) NULL DEFAULT ('N'),
		from_line_no int NULL,
		is_case int NULL DEFAULT ((0)),
		is_pattern int NULL DEFAULT ((0)),
		add_polarized varchar(1) NULL DEFAULT ('N'),
		is_polarized int NULL DEFAULT ((0)),
		is_pop_gif int NULL DEFAULT ((0)))

	EXEC dbo.CVO_create_fc_relationship_sp @order_no, @order_ext
	-- v1.2 End

	-- Remove old records
	DELETE FROM dbo.cvo_autopack_carton WHERE order_no = @order_no AND order_ext = @order_ext AND picked = 0

	-- START v1.3
	-- Create table
	CREATE TABLE #soft_alloc (
		line_no INT,
		part_no VARCHAR(30),
		qty DECIMAL (20,8))

	-- Group soft alloc records by line number
	INSERT INTO #soft_alloc(
		line_no,
		part_no,
		qty)
	SELECT 
		line_no,
		part_no,
		SUM(qty)
	FROM
		dbo.tdc_soft_alloc_tbl
	WHERE
		order_no = @order_no
		AND order_ext = @order_ext
		AND order_type = 'S'
	GROUP BY
		line_no, 
		part_no
	ORDER BY
		line_no

	-- Load into cartons
	SET @line_no = 0
	WHILE 1=1
	BEGIN
				
		SELECT TOP 1
			@line_no = line_no,
			@part_no = part_no,
			@qty = qty
		FROM
			#soft_alloc
		WHERE
			line_no > @line_no
		ORDER BY
			line_no

		/*
		SELECT TOP 1
			@line_no = line_no,
			@part_no = part_no,
			@qty = SUM(qty)
		FROM
			dbo.tdc_soft_alloc_tbl
		WHERE
			line_no > @line_no
			AND order_no = @order_no
			AND order_ext = @order_ext
			AND order_type = 'S'
		GROUP BY
			line_no, 
			part_no
		ORDER BY
			line_no
		*/
	-- END v1.3

		IF @@ROWCOUNT = 0
			BREAK
			
		-- If there are already picked lines for this line in the table then subtract the o/s from the qty to apply (as record already exists)
		SET @unpicked = 0
		SELECT	
			@unpicked = SUM(qty - picked)
		FROM
			dbo.cvo_autopack_carton
		WHERE
			order_no = @order_no 
			AND order_ext = @order_ext 
			AND line_no = @line_no
	
		SET @qty = @qty - ISNULL(@unpicked,0)
			
		IF @qty > 0
		BEGIN
			-- Create new records
			EXEC dbo.CVO_assign_to_autopack_carton_sp @order_no, @order_ext, @line_no, @part_no, @qty 
		END

	END

	-- v1.3
	DROP TABLE #soft_alloc

	-- Loop though and fix carton numbers
	SET @carton_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@carton_id = carton_id,
			@carton_no = carton_no
		FROM
			dbo.cvo_autopack_carton (NOLOCK)
		WHERE
			order_no = @order_no 
			AND order_ext = @order_ext 
			AND carton_no IS NOT NULL
			AND carton_id > @carton_id
		ORDER BY 
			carton_id

		IF @@ROWCOUNT = 0
			BREAK

		UPDATE
			dbo.cvo_autopack_carton
		SET
			carton_no = @carton_no
		WHERE
			order_no = @order_no 
			AND order_ext = @order_ext 
			AND carton_id = @carton_id
			AND carton_no IS NULL
	END

END

GO
GRANT EXECUTE ON  [dbo].[CVO_build_autopack_carton_sp] TO [public]
GO
