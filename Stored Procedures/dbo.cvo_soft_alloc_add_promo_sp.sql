SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CT 18/06/2013 - Issue #1311 - Don't add pop gifts which are obsolete and out of stock
-- v1.2 CB 26/06/2013 - Issue #1330 - Promo gifts get added again one allocated
-- v1.3 CT 18/10/2013 - Issue #1399 - IF promo is overridden the don't check frequency on pop gifts
-- v1.4 CB 02/02/2016 - When checking if item already exists on the order include ext > 0
-- v1.5 CB 12/03/2019 - #1680 POP Check

CREATE PROC [dbo].[cvo_soft_alloc_add_promo_sp]	@soft_alloc_no	int,
											@order_no		int,
											@order_ext		int,
											@customer_code	varchar(10),
											@location		varchar(10),
											@promo_id		varchar(40),
											@promo_level	varchar(40),
											@override		SMALLINT = 0 -- v1.3 
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@id			int,
			@last_id	int,
			@part_no	varchar(30),
			@qty		decimal(20,8),
			@retval		SMALLINT -- v1.1


	-- Create Working Table
	CREATE TABLE #promos (	id			int identity(1,1),
							part		varchar(30),
							description	varchar(255),
							qty			decimal(20,8))

	-- Execute the routine to return the promo items
	INSERT	#promos (part, description, qty)
	-- START v1.1
	EXEC	CVO_get_pop_gifs_sp @order_no, @order_ext, @customer_code, @promo_id, @promo_level, @override
	-- EXEC	CVO_get_pop_gifs_sp @order_no, @order_ext, @customer_code, @promo_id, @promo_level
	-- END v1.3

	IF EXISTS (SELECT 1 FROM #promos) -- Promo parts exist
	BEGIN

		-- Remove kits
		DELETE	a
		FROM	#promos a
		JOIN	inv_master_add b (NOLOCK)
		ON		a.part = b.part_no
		WHERE	ISNULL(b.field_30,'N') = 'Y'

		-- v1.5 Start
		DELETE	a
		FROM	#promos a
		JOIN	CVO_pop_gifts b (NOLOCK)
		ON		a.part = b.part
		WHERE	b.promo_id = @promo_id
		AND		b.promo_level = @promo_level
		AND		ISNULL(b.optional,0) = 1
		-- v1.5 End

		SET @last_id = 0

		SELECT	TOP 1 @id = id,
				@part_no = part,
				@qty = qty
		FROM	#promos
		WHERE	id > @last_id
		ORDER BY id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- v1.2 Start
-- v1.4			IF NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no
-- v1.4											AND ordered = @qty)
			IF NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND part_no = @part_no AND ordered = @qty) -- v1.4
			BEGIN

				-- START v1.1
				-- Check if the part is obsolete and out of stock
				EXEC @retval = dbo.cvo_promo_obsolete_check_sp @part_no, @location, @qty,@order_no, @order_ext, -1, @soft_alloc_no

				IF @retval = 0
				BEGIN
					-- Call the routine to add the promo items to the soft allocation
					EXEC dbo.cvo_add_soft_alloc_line_sp	@soft_alloc_no, @order_no, @order_ext, -1, @location, @part_no, @qty, 0, 0, 0, 0, '', ''		
				END
				-- END v1.1
			END
			-- v1.2 End

			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@part_no = part,
					@qty = qty
			FROM	#promos
			WHERE	id > @last_id
			ORDER BY id ASC

		END
	END

	DROP TABLE #promos

END
GO

GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_add_promo_sp] TO [public]
GO
