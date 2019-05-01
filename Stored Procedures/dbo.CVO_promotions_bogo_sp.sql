SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CB 31/12/2018 - #1678 Promo Updates
-- v1.1 CB 19/03/2019 - Fix issue with first frame being given as free
-- v1.2 CB 25/03/2019 - Add validation errors
-- v1.3 CB 13/04/2019 - Logic Change

CREATE PROC [dbo].[CVO_promotions_bogo_sp] (@promo_id varchar(30),	
										@promo_level varchar(30),
										@spid int,
										@override smallint = 0) 
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @rec_id				int,
			@brand				varchar(30),
			@gender_check		char(1),
			@attribute			char(1),
			@promo_line_no		int,
			@actual_qty			int,
			@free_qty			int,
			@line_no			int,
			@apply_qty			decimal(20,8),
			@split				smallint,
			@qty				decimal(20,8),
			@min_qty			int,
			@max_qty			int,
			@bogo_buy_qty		int,
			@bogo_get_qty		int,
			@adt_brand			varchar(30), -- v1.3
			@adt_gender_check	char(1), -- v1.3
			@adt_attribute		char(1), -- v1.3
			@errset				int, -- v1.2
			@discount			decimal(20,8) -- v1.3

	-- WORKING TABLES
	CREATE TABLE #ff_ord_list (
			part_no		VARCHAR(30),
			line_no		INT,
			brand		VARCHAR(30),
			category	VARCHAR(30),
			ordered		DECIMAL(20, 8),			
			gender		VARCHAR(15),							
			attribute	VARCHAR(10))

	CREATE TABLE #selected_ord_list (
			part_no		VARCHAR(30),
			line_no		INT,
			brand		VARCHAR(30),
			category	VARCHAR(30),
			ordered		DECIMAL(20, 8),		
			gender		VARCHAR(15),							
			attribute	VARCHAR(10))

	-- PROCESSING
	-- Load working ord_list table
	INSERT 	#ff_ord_list(part_no, line_no, brand, category, ordered, gender, attribute)
	SELECT	a.part_no, a.line_no, i.category, i.type_code, a.ordered, ISNULL(ia.category_2,''), ISNULL(ia.field_32,'')	
	FROM	dbo.cvo_bogo_apply a
	JOIN	dbo.inv_master i (NOLOCK) 
	ON		a.part_no = i.part_no
	JOIN	inv_master_add ia (NOLOCK) 
	ON		a.part_no = ia.part_no
	WHERE	a.spid = @spid 	

	-- Loop through the order qualifications lines that have passed and are for bogo
	SET @rec_id = 0
	
	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @rec_id = rec_id,
				@bogo_buy_qty = buy_qty,
				@bogo_get_qty = get_qty,
				@brand = ISNULL(brand,''),
				@gender_check = gender_check,
				@attribute = attribute_check,
				@promo_line_no = line_no,
				@discount = adt_discount,
				@adt_brand = ISNULL(adt_brand,''),
				@adt_gender_check = adt_gender_check,
				@adt_attribute = adt_attribute_check
		FROM	dbo.CVO_bogo_qualified (NOLOCK)
		WHERE	rec_id > @rec_id
		AND		spid = @spid
		AND		promo_id = @promo_id
		AND		promo_level = @promo_level
		ORDER BY rec_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		-- Clear temp ord_list table
		DELETE FROM #selected_ord_list

		-- v1.2 Start
		SET @errset = 0
		IF (ISNULL(@override,0) = 0)
		BEGIN

			IF (ISNULL(@brand,'') <> '')
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM #ff_ord_list WHERE brand = @brand)
				BEGIN
					UPDATE	dbo.cvo_bogo_apply
					SET		error_desc = 'Buy One Get One was not applied - Buy One Brand is not on the order'
					WHERE	spid = @spid

					SET @errset = 1
				END
			END

			IF (ISNULL(@adt_brand,'') <> '')
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM #ff_ord_list WHERE brand = @adt_brand)
				BEGIN
					UPDATE	dbo.cvo_bogo_apply
					SET		error_desc = 'Buy One Get One was not applied - Discount Brand is not on the order'
					WHERE	spid = @spid

					SET @errset = 1
				END
			END

			IF (ISNULL(@gender_check,'N') = 'Y')
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM #ff_ord_list WHERE gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'B')) 
				BEGIN
					UPDATE	dbo.cvo_bogo_apply
					SET		error_desc = 'Buy One Get One was not applied - Buy One specified gender is not on the order'
					WHERE	spid = @spid

					SET @errset = 1
				END
			END

			IF (ISNULL(@adt_gender_check,'N') = 'Y')
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM #ff_ord_list WHERE gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'A')) 
				BEGIN
					UPDATE	dbo.cvo_bogo_apply
					SET		error_desc = 'Buy One Get One was not applied - Discount specified gender is not on the order'
					WHERE	spid = @spid

					SET @errset = 1
				END
			END

			IF (ISNULL(@attribute,'N') = 'Y')
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM #ff_ord_list a LEFT JOIN cvo_part_attributes b (NOLOCK) ON a.part_no = b.part_no
					WHERE ((b.part_no) IS NULL OR (b.attribute NOT IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
									  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'B'))))
				BEGIN
					UPDATE	dbo.cvo_bogo_apply
					SET		error_desc = 'Buy One Get One was not applied - Buy One specified attribute is not on the order'
					WHERE	spid = @spid

					SET @errset = 1
				END
			END

			IF (ISNULL(@adt_attribute,'N') = 'Y')
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM #ff_ord_list a LEFT JOIN cvo_part_attributes b (NOLOCK) ON a.part_no = b.part_no
					WHERE ((b.part_no) IS NULL OR (b.attribute NOT IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
									  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'A'))))
				BEGIN
					UPDATE	dbo.cvo_bogo_apply
					SET		error_desc = 'Buy One Get One was not applied - Discount specified attribute is not on the order'
					WHERE	spid = @spid

					SET @errset = 1
				END
			END

			IF (@errset = 1)
			BEGIN
				SELECT	line_no,
						free_qty,
						split,
						discount,
						error_desc	-- v1.2
				FROM	dbo.cvo_bogo_apply (NOLOCK)
				WHERE	spid = @spid
				AND		ISNULL(error_desc,'') <> ''
				ORDER BY line_no

				RETURN
			END
		END
		-- v1.2 End

			-- Load order lines which match
		INSERT	#selected_ord_list(part_no, line_no, brand, category, ordered, gender, attribute)
		SELECT	part_no, line_no, brand, category, ordered, gender, attribute	
		FROM	#ff_ord_list (NOLOCK)
		WHERE	(((ISNULL(@brand,'') <> '' AND brand = @brand) OR (ISNULL(@brand,'') = ''))
		AND		((ISNULL(@gender_check,'N') = 'N') OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'B')))
		OR		(((ISNULL(@adt_brand,'') <> '' AND brand = @adt_brand) OR (ISNULL(@adt_brand,'') = '')))
		AND		((ISNULL(@adt_gender_check,'N') = 'N') OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'A'))))
 
		-- v1.3 Start
		IF ((ISNULL(@attribute,'N') <> 'N'))
		BEGIN

			CREATE TABLE #buy_attribute_check (
				part_no		varchar(30),
				attribute	varchar(30))

			INSERT	#buy_attribute_check
			SELECT	a.part_no, b.attribute 
			FROM	#selected_ord_list a
			JOIN	cvo_part_attributes b (NOLOCK)
			ON		a.part_no = b.part_no
			JOIN	dbo.cvo_promotions_attribute c (NOLOCK) 
			ON		b.attribute = c.attribute
			WHERE	((ISNULL(@brand,'') <> '' AND brand = @brand) OR (ISNULL(@brand,'') = ''))
			AND		((ISNULL(@gender_check,'N') = 'N') OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'B')))
			AND		c.promo_id = @promo_id AND c.promo_level = @promo_level and c.line_no = @promo_line_no AND c.line_type = 'B'						

			DELETE	a
			FROM	#selected_ord_list a
			LEFT JOIN #buy_attribute_check b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	b.part_no IS NULL
			AND		((ISNULL(@brand,'') <> '' AND brand = @brand) OR (ISNULL(@brand,'') = ''))
			AND		((ISNULL(@gender_check,'N') = 'N') OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'B')))

			DROP TABLE #buy_attribute_check
		END

		IF ((ISNULL(@adt_attribute,'N') <> 'N'))
		BEGIN

			CREATE TABLE #adt_attribute_check (
				part_no		varchar(30),
				attribute	varchar(30))

			INSERT	#adt_attribute_check
			SELECT	a.part_no, b.attribute 
			FROM	#selected_ord_list a
			JOIN	cvo_part_attributes b (NOLOCK)
			ON		a.part_no = b.part_no
			JOIN	dbo.cvo_promotions_attribute c (NOLOCK) 
			ON		b.attribute = c.attribute
			WHERE	((ISNULL(@adt_brand,'') <> '' AND brand = @adt_brand) OR (ISNULL(@adt_brand,'') = ''))
			AND		((ISNULL(@adt_gender_check,'N') = 'N') OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'A')))
			AND		c.promo_id = @promo_id AND c.promo_level = @promo_level and c.line_no = @promo_line_no AND c.line_type = 'A'						

			DELETE	a
			FROM	#selected_ord_list a
			LEFT JOIN #adt_attribute_check b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	b.part_no IS NULL
			AND		((ISNULL(@adt_brand,'') <> '' AND brand = @adt_brand) OR (ISNULL(@adt_brand,'') = ''))
			AND		((ISNULL(@adt_gender_check,'N') = 'N') OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'A')))

			DROP TABLE #adt_attribute_check
		END
		-- v1.3 End

		-- Remove lines which don't meet the min qty frame/sun setting
		DELETE FROM #selected_ord_list WHERE category NOT IN ('FRAME','SUN')

		IF NOT EXISTS (SELECT 1 FROM #selected_ord_list)
		BEGIN
			UPDATE	dbo.cvo_bogo_apply
			SET		error_desc = 'Buy One Get One was not applied. No qualifying order lines exist.'
			WHERE	spid = @spid

			SELECT	line_no,
					free_qty,
					split,
					discount,
					error_desc	
			FROM	dbo.cvo_bogo_apply (NOLOCK)
			WHERE	spid = @spid
			AND		ISNULL(error_desc,'') <> ''
			ORDER BY line_no

			RETURN
		END
		
		-- Get qty on order
		SELECT	@actual_qty = CAST(SUM(ordered) AS INT)
		FROM	#selected_ord_list 
		WHERE	((ISNULL(@brand,'') <> '' AND brand = @brand) OR (ISNULL(@brand,'') = ''))
		AND		((ISNULL(@gender_check,'N') = 'N') OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
									WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'B')))

		IF (@bogo_buy_qty <> 0)
		BEGIN
			IF ((ISNULL(@actual_qty,0) >= @bogo_buy_qty) OR @override = 1)
			BEGIN
				SET @free_qty = @bogo_get_qty

				SELECT	@actual_qty = CAST(SUM(ordered) AS INT)
				FROM	#selected_ord_list 
				WHERE	((ISNULL(@adt_brand,'') <> '' AND brand = @adt_brand) OR (ISNULL(@adt_brand,'') = ''))
				AND		((ISNULL(@adt_gender_check,'N') = 'N') OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
											WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'A')))

				IF (@actual_qty < @free_qty)
					SET @free_qty = @actual_qty

				-- Loop through lines and apply until free_qty is 0 or no more lines left
				WHILE @free_qty > 0
				BEGIN
					SELECT	TOP 1 @line_no = a.line_no,
							@qty = a.ordered
					FROM	dbo.cvo_bogo_apply a (NOLOCK)
					JOIN	#selected_ord_list b (NOLOCK)
					ON		a.line_no = b.line_no
					WHERE	a.spid = @spid
					AND		((ISNULL(@adt_brand,'') <> '' AND b.brand = @adt_brand) OR (ISNULL(@adt_brand,'') = ''))
					AND		((ISNULL(@adt_gender_check,'N') = 'N') OR (b.gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
											WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'A')))
					ORDER BY a.price ASC, a.line_no ASC

					IF (@@ROWCOUNT = 0)
						BREAK

					IF (@discount = 100)
					BEGIN
						IF (@qty > @free_qty)
						BEGIN
							SET @apply_qty = @free_qty

							UPDATE	dbo.cvo_bogo_apply
							SET		free_qty = @apply_qty,
									split = 1,
									is_free = 1,
									discount = @discount
							WHERE	spid = @spid
							AND		line_no = @line_no
						
							SET @free_qty = 0
						END
						ELSE
						BEGIN

							SET @apply_qty = @qty

							UPDATE	dbo.cvo_bogo_apply
							SET		free_qty = @apply_qty,
									split = 0,
									is_free = 1,
									discount = @discount
							WHERE	spid = @spid
							AND		line_no = @line_no
						
							SET @free_qty = @free_qty - @qty
						END
					END
					ELSE
					BEGIN
						IF (@qty > @free_qty)
						BEGIN
							SET @apply_qty = @free_qty

							UPDATE	dbo.cvo_bogo_apply
							SET		free_qty = @apply_qty,
									split = 1,
									is_free = 0,
									discount = @discount
							WHERE	spid = @spid
							AND		line_no = @line_no
						
							SET @free_qty = 0
						END
						ELSE
						BEGIN

							SET @apply_qty = @qty

							UPDATE	dbo.cvo_bogo_apply
							SET		free_qty = @apply_qty,
									split = 0,
									is_free = 0,
									discount = @discount
							WHERE	spid = @spid
							AND		line_no = @line_no
						
							SET @free_qty = @free_qty - @qty
						END
					END
				END
			END
			ELSE
			BEGIN
				-- v1.2 Start
				UPDATE	dbo.cvo_bogo_apply
				SET		error_desc = 'Buy One Get One was not applied. Buy quantity not reached.'
				WHERE	spid = @spid
				-- v1.2 End
			END
		END
		ELSE
		BEGIN			
			UPDATE	dbo.cvo_bogo_apply
			SET		error_desc = 'Buy One Get One was not applied. Buy quantity not reached.'
			WHERE	spid = @spid
		END
	END


	-- Return rows to be given for free
	SELECT	line_no,
			free_qty,
			split,
			discount,
			error_desc	-- v1.2
	FROM	dbo.cvo_bogo_apply (NOLOCK)
	WHERE	spid = @spid
	ORDER BY line_no

END
GO
GRANT EXECUTE ON  [dbo].[CVO_promotions_bogo_sp] TO [public]
GO
